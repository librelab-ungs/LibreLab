# -*- coding: utf-8 -*-

"""
serial_board module
===================

This module contains the main class (SerialDAQ) for the serial data
acquisition device.

Internally, the SerialDAQ object communicates with the real hardware
through a given serial port by means of the pySerial library.

The communication is based on a simple command-response protocol, in
which the computer sends a command and the data acquisition device
gives a response (by sending data back or executing an action). The
command set is described in a companion file (protocol.txt). Many of
the methods of this class are simply wrappers around these basic
commands, which in turn are defined by the device's firmware.

The data acquisition device has a number (NUM_CHANNELS) of analog-to-
digital input channels with a given resolution (ADC_BITS) that can be
read (individually or jointly) in one of three (mutually exclusive) modes:

    1. on demand
    2. continuous (streaming) mode
    3. burst mode

Before issuing any of these modes, a connection with the board must be
established and the channels have to be configured.

"""

from __future__ import division, absolute_import, print_function

import time
import struct
import serial
from serial.tools.list_ports import comports
from serial import SerialException

import numpy as np


command = {"GETINFO": chr(27) + b"e",           # Get board information
           "STOPALL": chr(27) + b"P",           # Stop all activities
           "AREADCHN": chr(27) + b"b",          # Read given analog channel
           "AREADALL": chr(27) + b"a",          # Read all analog channels
           "ASTARTCONT": chr(27) + b"T",        # Start continuous analog read
           "ASTOPCONT": None,                   # Not implemented yet
           "ASTARTBURST": chr(27) + b"O",       # Start burst mode
           "ACFGCHN": chr(27) + b"A"            # Set number of analog channels
           }


# Default values
BAUDRATE = 57600
TIMEOUT = 0.2
NUM_CHANNELS = 8
ADC_BITS = 10
ADC_REFERENCE = 5.0
DEFAULT_OFFSET = 0.0
DEFAULT_SLOPE = ADC_REFERENCE / 2**ADC_BITS


class SerialDAQ(object):
    """
    Main class of the Data Acquisition Interface (serial version).

    """

    def __init__(self,
                 port="auto",
                 baudrate=BAUDRATE,
                 timeout=TIMEOUT,
                 debug=False,
                 delay=0.1,
                 bufsize=100000):
        """
        Initializes a SerialDAQ object.

        Parameters
        ==========

        port : string
                    String containing the serial device's port name,
                    i.e. '/dev/ttyS0' in Linux, 'COM1' in Windows, etc.

                    If port='auto', it tries to autodetect the board port.

                    If port='sim', the serial device is simulated and the
                    actual hardware is not needed (for software testing
                    purposes).

        baudrate :
                    Serial port baudrate (must match the device baudrate).

        timeout

                    Serial port timeout value (see pyserial module
                    documentation).

        debug
                    If True, all methods print runtime debug information
                    messages (for testing purposes). **NOT IMPLEMENTED**.

        delay
                    Time to wait after configuration commands (in seconds).
                    For compatibility with Arduino Mega2560, probably could
                    be discarded in the final version.

        Examples
        ========

        >>>
        >>>
        >>>

        Returns a SerialDAQ object.
        """

        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.simulate = (port == "sim")    # **TODO**: to be implemented
        self.debug = debug
        self.delay = delay
        self.bufsize = bufsize

        # Let's open the device and store the result in self.connected
        self.connected = self.open()

        # Initializes internal state
        self.measuring = False             # Initial state: not measuring
        self.continuous_mode = False
        self.burst_mode = False
        self.logger_mode = False

        self.channel_name = ['' for i in range(NUM_CHANNELS)]
        self.channel_quantity = ['' for i in range(NUM_CHANNELS)]
        self.channel_unit = ['' for i in range(NUM_CHANNELS)]
        self.channel_calib = [(DEFAULT_OFFSET, DEFAULT_SLOPE) for i in range(NUM_CHANNELS)]
        self.channel_data = [np.zeros(1) for i in range(NUM_CHANNELS)]
        self.channel_active = [False for i in range(NUM_CHANNELS)]
        # Initializes the channel pointer for continuous measurements
        self.channel_pointer = 0

        # First analog input channel enabled by default
        self.enabled_channels = 1

        # If successfully connected, do a basic analog config (activate the
        # first analog channel and create empty buffers for all channels)
        if self.connected:
            self.config_analog(1, name="Channel 1", activate=True)

            for i in range(2, NUM_CHANNELS + 1):
                self.config_analog(i, "Channel " + str(i), activate=False)
        

    def open(self):
        """
        Tries to open the serial device using the parameter values stored in
        the initialization.

        Returns
        =======

        True
                The device was opened correctly.

        False
                There was a problem opening the device.

        *TO BE IMPLEMENTED: Exceptions for opening errors.*
        """

        if self.simulate:
            # Use a simulation, not the real thing
            print ("Feature not implemented (yet)")
            return False

        if self.port == "auto":
            # Try to autodetect the board's port
            port_list = self.discover_ports()

            if port_list == []:
                print("Autodetection failed")
                return False

            else:
                # Selects the first port discovered
                self.port = port_list[0]
                self.board = serial.Serial(port=self.port,
                                           baudrate=self.baudrate,
                                           timeout=self.timeout)
                return True

        # The port is explicitly given
        try:
            self.board = serial.Serial(port=self.port,
                                       baudrate=self.baudrate,
                                       timeout=self.timeout)
        except SerialException:
            print ("Cannot open serial port {0}".format(self.port))
            return False    # Failed opening the device

        # time.sleep(self.delay * 5.)    # For compatibility with Arduino

        # Flush input and output serial buffers (may contain garbage)
        self.board.flushOutput()
        self.board.flushInput()

        self.board.write(command['GETINFO'])
        info = self.board.read(1)
        if info:
            info = info + self.board.read(200)

        if info[0:3] == 'Pro':
            return True     # Successfully opened!
        else:
            self.board.close()
            return False    # Board not detected (failure)
    
    def close(self):
        
        if self.connected:
            self.board.close()
            self.connected = False
            

    def get_info(self):
        """
        Get the board's information/identification string.
        The format has not been defined yet, but probably it will include
        an ID string, board version number, firmware version number, etc.
        It will be needed for device and capabilities detection.

        """

        self.board.write(command['GETINFO'])
        info = self.board.read(1)
        if info:                            # if not timeout
            # read until nothing left in buffer (timeout must be != 0)
            info = info + self.board.read(200)
            return info
        else:
            return b""                      # no response, return null string

    def config_analog(self, number, name="", quantity="quantity",
                      unit="units", calib=(DEFAULT_OFFSET, DEFAULT_SLOPE ),
                      activate=True, clear=True):
        """
        Configures an analog channel
        """
        if self.connected:
            if not self.measuring:

                self.channel_name[number - 1] = name
                self.channel_quantity[number - 1] = quantity
                self.channel_unit[number - 1] = unit
                self.channel_calib[number - 1] = calib

                if clear:
                    self.channel_data[number - 1] = np.zeros(self.bufsize)

                if activate:
                    self.activate_analog(number)
                else:
                    self.deactivate_analog(number)

    def set_analog_number(self, number):

        self.enabled_channels = number
        self.board.write(command['ACFGCHN'])
        self.board.write(str(number))
        time.sleep(self.delay)

    def activate_analog(self, channel):

        if not self.measuring:
            if channel > self.enabled_channels:
                self.set_analog_number(channel)

            self.channel_active[channel - 1] = True

    def deactivate_analog(self, channel):

        if not self.measuring:
            if channel == self.enabled_channels:
                i = self.enabled_channels - 1
                while not self.channel_active[i - 1]:
                    i -= 1
                self.set_analog_number(i)

            self.channel_active[channel - 1] = False

    def read_analog(self, channel):
        """
        Read the value of the specified analog channel.

        *TO BE IMPLEMENTED: input validation (right now,
        we have only 8 channels).*

        Parameters
        ==========

        channel
                    Analog channel number to be read.

        Returns
        =======

        A (signed) 10 bit integer.

        Examples
        ========

        >>>
        >>>
        >>>
        """

        if not self.measuring:      # this command is not compatible
                                    # with other kinds of measurements

            self.board.write(command["AREADCHN"])
            self.board.write(str(channel))

            # read 2 bytes (least significant first)
            indata = self.board.read(2)

            # unpack 2 bytes as a signed 16-bit integer
            return struct.unpack('<h', indata)[0]

    def read_analog_all(self, fmt='a'):
        """
        Reads all the active analog channels and returns the corresponding
        values in the requested format (numpy array, tuple or raw bytes).

        Parameters
        ==========

        fmt
                a character indicating the format of returned values

                * 'a' returns a numpy array
                * 'r' returns the raw bytes (as read from the device)
                * 't' returns a tuple
        """

        if not self.measuring:

            self.board.write(command['AREADALL'])

            # Number of bytes to read = number of channels * 2
            data = self.board.read(self.enabled_channels * 2)
            
            if fmt == 'a':
                data_array = np.ndarray(shape=(self.enabled_channels, ),
                                        dtype='<h', buffer=data, order='C')
                return data_array

            if fmt == 't':
                return struct.unpack('<' + self.enabled_channels * 'h', data)

            if fmt == 'r':
                return data

    def start_continuous(self, frequency, trigger=0, threaded=False):
        """
        Starts continuous mode.

        Parameters
        ==========

        frequency
                    Sampling frequency in Hertz.

        trigger
                    Trigger source:

                    * 0 = starts inmediately (no trigger)
                    * 1 = software source (*TO BE IMPLEMENTED*)
                    * 2 = hardware source (*TO BE IMPLEMENTED*)

                    Hardware sources can be hardware interrupts or pin changes.

        threaded
                    If True, launches a threaded reader.
                    *TO BE IMPLEMENTED*

        Returns
        =======
        None (rigth now).

        Examples
        ========

        >>>
        >>>
        >>>

        """

        if not self.measuring:

            self.measuring = True
            self.continuous_mode = True

            self.threaded = threaded
            if threaded:
                pass        # Not implemented (yet)

            self.frequency = frequency
            # The board expects a period in hundreds of microseconds
            # so we must convert freq -> period.
            period_100_us = int(10000. / frequency)

            self.board.write(command["ASTARTCONT"])
            self.board.write(str(period_100_us))
            self.board.write("\r\n")

            time.sleep(self.delay)

    def stop(self):
        """
        Stop all board activities. Rigth now, is the only way to stop
        continuous measurements (the only implemented mode).

        """

        self.update_analog()        # Updates internal buffers before stopping

        self.measuring = False

        

        self.board.write(command["STOPALL"])
        
        self.stop_continuous()              # stop continuous mode

        if self.board.inWaiting():
            self.board.flushInput()         # discard the unread bytes

    

    def stop_continuous(self):
        """
        Stops continuous mode. Unread data will be lost.
        """

        if self.continuous_mode:
            self.continuous_mode = False
            

    def read_analog_buffer(self, size=0, fmt='a'):
        """
        Returns last data read in continuous mode.

        Parameters
        ==========
        size
                Number of 16-bit samples to read for each channel.

                If size=0, reads all available values in the incoming serial
                buffer.

                If continuous threaded mode is active, data is read from the
                internal buffer. *TO BE IMPLEMENTED*

        fmt
                Return format:

                * 'a' = NumPy array
                * 'r' = raw bytes
                * 't' = list of tuples

        Returns
        =======

        * NumPy array

            rows are channels, columns are sample numbers

        * Raw bytes (*TO BE IMPLEMENTED*)

        * List of tuples (*TO BE IMPLEMENTED*)

            list[channel-1] is a tuple holding samples for the specified
            channel

        Examples
        ========

        >>>
        >>>
        >>>

        """

        if self.continuous_mode:

            if not self.board.inWaiting():
                return None     # nothing to read, return none

            if size == 0:    # Reads (almost) all available data

                # We have to read a number of 16-bit words
                # which is a multliple of the number of active channels
                waiting = int(self.board.inWaiting() / 2.)  # Number of words
                residue = waiting % self.enabled_channels

                # The number of bytes to read is twice the number of words
                data_words = waiting - residue

            else:
                data_words = size * self.enabled_channels

            data = self.board.read(data_words * 2)

            data_array = np.ndarray(shape=(self.enabled_channels, data_words /
                                    self.enabled_channels), dtype='<h',
                                    buffer=data, order='F')

            return data_array

    def update_analog(self, size=0):
        """
        Adds new data to the active channels from serial buffer.
        Data are stored in channel_data structure taking into account the
        channel's calibration (not stored as raw samples).

        Parameters
        ==========

        size
                Number of samples to read for each active channel. If size=0,
                reads all available data.

        Returns
        =======

        Number of samples added to each active channel.

        """

        if self.continuous_mode:

            buf = self.read_analog_buffer(size)

            if buf is None:
                return 0

            data = self.channel_data

            # print ("Buf=", buf)

            # Section of the channel buffer to update
            start = self.channel_pointer
            stop = self.channel_pointer + buf.size / self.enabled_channels

            # print ("Range=", start, stop)

            for i in range(self.enabled_channels):
                if self.channel_active[i]:
                    pendiente = self.channel_calib[i][1]
                    ordenada = self.channel_calib[i][0]
                    data[i][start:stop] = \
                        buf[i] * pendiente + ordenada

            self.channel_pointer = stop     # updates pointer for next read
            return stop - start

    def clear_analog(self):
        """
        Clear all internal buffers for analog channels and resets the pointer.
        """

        self.channel_pointer = 0
        self.channel_data = [np.zeros(self.bufsize)
                             for i in range(NUM_CHANNELS)]

    def discover_ports(self):

        port_list = comports()

        detected_port_list = []

        for port_name, port_desc, port_hw in port_list:

            # print port_name, port_desc, port_hw

            try:
                # Try to open the port
                board = serial.Serial(port_name, baudrate=BAUDRATE,
                                      timeout=TIMEOUT)
                time.sleep(self.delay * 10)    # Delay needed for Arduino

                # Flush any incoming and outcoming serial data
                board.flushOutput()
                board.flushInput()

                while board.inWaiting():
                    board.read(board.inWaiting())

                # Here the ID command is sent

                board.write(command['GETINFO'])
                info = board.read(1)

                if info:
                    info = info + board.read(200)

                if info[0:3] == 'Pro':
                    detected_port_list.append(port_name)

                board.close()

            except SerialException:
                pass

        return detected_port_list


if __name__ == "__main__":
    sb = SerialDAQ() #"/dev/pts/4")
