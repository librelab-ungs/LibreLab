# -*- coding: utf-8 -*-


# ===============================
# Módulos de la librería estándar
# ===============================
import sys
import time

# ===================
# Módulos de terceros
# ===================
from PyQt4.QtCore import Qt, QTimer
from PyQt4.QtGui import (QAction, QApplication, QIcon, QListWidget,
                         QMainWindow, QSplitter, QTextBrowser, QTextEdit,
                         QStatusBar, QPushButton, QDialog, QWidget,
                         QSplashScreen, QPixmap, QMessageBox)

import pyqtgraph as pg
import numpy as np

# ===============
# Módulos propios
# ===============

from serial_daq import SerialDAQ

# import ui_bienvenida
import ui_principal
import ui_grafico

ADC_BITS = 10
ADC_REF = 4.096
NUM_CANALES = 8

PENDIENTE_DEF = ADC_REF / 2 ** ADC_BITS

TIME_RANGE = 4.0


class Grafico(QWidget, ui_grafico.Ui_Form):
    def __init__(self, parent=None, number=0):
        super(Grafico, self).__init__()

        self.setupUi(self)
        self.move(parent.x() + parent.frameSize().width(),
                  parent.y() + number * self.frameSize().height())

    # def closeEvent(self, event):
    #    event.ignore()



class Principal(QMainWindow, ui_principal.Ui_Principal):

    def __init__(self, parent=None):

        QMainWindow.__init__(self)
        self.setupUi(self)

        print (pg.__version__)
        
        self.sb = SerialDAQ() #'/dev/pts/6')

        while not self.sb.connected:

            msg = QMessageBox.critical(None, "Advertencia",
                                       u"La interfaz no está conectada",
                                       QMessageBox.Retry | QMessageBox.Abort)

            if msg == QMessageBox.Retry:
                self.sb.open()
            else:
                sys.exit(1)

        self.updateTimer = QTimer()
        self.updateTimer.timeout.connect(self.update)

        # Asigna valores iniciales por defecto a los parámetros de cada canal
        for i in range(NUM_CANALES):

            str_pendiente = 'pendiente_' + str(i + 1)
            pendiente = getattr(self, str_pendiente)

            str_ordenada = 'ordenada_' + str(i + 1)
            ordenada = getattr(self, str_ordenada)

            str_nombre = 'nombre_' + str(i + 1)
            nombre = getattr(self, str_nombre)

            str_unidad = 'unidad_' + str(i + 1)
            unidad = getattr(self, str_unidad)

            pendiente.setText(str(PENDIENTE_DEF))
            ordenada.setText(str(0.0))

            nombre.setText('Canal ' + str(i + 1))
            unidad.setText('Volt')

            self.sb.config_analog(i + 1, 
                                  name=nombre.text(),
                                  activate=False,
                                  calib=(float(ordenada.text()),
                                         float(pendiente.text())))
        self.sb.activate_analog(1)
        self.midiendo = False
        self.guardado = True
        
        self.vent_grafico = []
        self.grafico = []
        
        self.actionMedir.triggered.connect(self.medir)
        self.actionGuardar.triggered.connect(self.guardar)
        self.actionSalir.triggered.connect(self.close)
        
        pg.setConfigOption('background', 'w')
        pg.setConfigOption('foreground', 'k')
        
    
    def guardar(self):
        
        self.guardado = True

    def medir(self):

        if not self.midiendo:
            if not self.guardado:
                msg = QMessageBox.critical(None, "Advertencia",
                                       u"Se perderán los datos actuales",
                                       QMessageBox.Ok | QMessageBox.Cancel)
                if msg == QMessageBox.Cancel:
                    return

            self.guardado = False
            self.midiendo = True
            
            self.vent_grafico = []
            self.grafico = []
            self.sb.clear_analog()
            
            print(u'Iniciando medición')
            self.actionMedir.setIconText('Detener')

            self.frecuencia = self.frecuenciaSpinBox.value()
            self.num_ventana = 0
            
            self.cur_range = 0

            print "Frecuencia deseada =",  1. / self.frecuencia
            print "Frecuencia deseada =",  int(10000. / self.frecuencia) * 0.0001
            self.timestamp = 1.065 * 0.0001 * int(10000./self.frecuencia) * np.arange(0, self.sb.bufsize)
            
            
            for i in range(NUM_CANALES):

                gb = getattr(self, 'groupBox_' + str(i + 1))
                nombre = getattr(self, 'nombre_' + str(i + 1))

                str_pendiente = 'pendiente_' + str(i + 1)
                pendiente = getattr(self, str_pendiente)

                str_ordenada = 'ordenada_' + str(i + 1)
                ordenada = getattr(self, str_ordenada)

                self.sb.config_analog(i + 1, name=nombre.text(),
                                      activate=gb.isChecked(),
                                      calib=(float(ordenada.text()),
                                             float(pendiente.text())))

                if self.sb.channel_active[i]:

                    print('Canal {0} activo.'.format(str(i + 1),))

                    self.vent_grafico.append(Grafico(self, self.num_ventana))
                    
                    self.num_ventana += 1
                    self.grafico.append(self.vent_grafico[i].graphicsView.plot(autoDownsample=False, clipToView=True, antialias=True, pen=pg.mkPen('r', width=1.), symbol='o', symbolSize=4, symbolPen=pg.mkPen('r', width=1), symbolBrush=pg.mkBrush('r')))
                    title = 'Canal {0}: '.format(str(i + 1)) + \
                            self.sb.channel_name[i]

                    self.vent_grafico[i].setWindowTitle(title)
                    self.vent_grafico[i].graphicsView.setYRange(0., self.sb.channel_calib[i][1] * 2**ADC_BITS)
                    # self.vent_grafico[i].graphicsView.setXRange(0., TIME_RANGE )
                    
                    #.setLimits(maxXRange=100, minXRange=50)
                    #self.grafico[i].setDownsampling(auto=True)
#                    self.vent_grafico[i].graphicsView.setXRange(0., 50.)
                    self.vent_grafico[i].show()

                else:

                    print('Canal {0} inactivo.'.format(str(i + 1), ))
                    self.grafico.append(None)
                    self.vent_grafico.append(None)

            self.sb.start_continuous(self.frecuencia)

            self.updateTimer.start(50) #1./self.frecuencia*1000)

        else:
            self.midiendo = False
            print(u'Deteniendo medición')
            self.actionMedir.setIconText('Medir')

            self.updateTimer.stop()
            self.sb.update_analog()
            self.sb.stop()

            # self.vent_grafico = []
            # 

    def update(self):

        self.sb.update_analog()
        
        new_range = False

        if (self.sb.channel_pointer / self.frecuencia) / TIME_RANGE > self.cur_range:
            self.cur_range += 1
            new_range = True
        # print self.cur_range
        for i in range(NUM_CANALES):

            if self.sb.channel_active[i]:
#                if new_range:
#                    self.vent_grafico[i].graphicsView.setXRange((self.cur_range - 1) * TIME_RANGE, self.cur_range * TIME_RANGE )
                    
                    
                self.grafico[i].setData(
                    self.timestamp[0:self.sb.channel_pointer],
                    self.sb.channel_data[i][0:self.sb.channel_pointer])

    def closeEvent(self, event):

        if not self.guardado:
            msg = QMessageBox.critical(None, "Salir",
                                       u"Se perderán los datos actuales",
                                       QMessageBox.Ok | QMessageBox.Cancel)
            if msg == QMessageBox.Cancel:
                    event.ignore()
                    return

        for ventana in self.vent_grafico:
            if ventana is not None:
                ventana.destroy()

        event.accept()


app = QApplication(sys.argv)

principal = Principal()
principal.show()

app.exec_()

for w in app.allWidgets():
    print(w.objectName(), w)





