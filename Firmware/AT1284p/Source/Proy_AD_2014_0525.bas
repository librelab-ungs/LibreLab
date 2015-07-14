'--------------------------------------------------------------
'                  2014 - Proyecto - AD
'--------------------------------------------------------------
'      8 Canales Analógicos + 8 Canales Digitales
'--------------------------------------------------------------
'--------------------------------------------------------------
'NOTAS:
'
'20/03/2014
'Recompilación del programa original para Mega32 en Mega1284
'
'21/02/2014
'Se cambia la recepción por interrupción
'
'03/05/2014
'Se cambia manejo de ESC por tipo "Toggle" y encendido de led "Testigo"
'
'04/05/2014 - Ver:1.2
'Se agregaron las rutinas de la E2 (24LS256) y el Reloj de tiempo real (DS1307)
'
'07/05/2014 - Ver: 1.3
'Se pasa I2C por soft a TWI por hard, usando bliblioteca "i2c_twi.lbx"
'
'11/05/2014 - Ver: 1.4
'Se pone la conversión como interrupción
'Se incorpora testeo de stacks
'Se emprolija código y constantes
'
'12/05/2014 - Ver: 1.5
'Se pasa a transmisión binaria
'
'18/05/2014 - Ver: 1.6
'Se cambia la forma de setear los canales analógicos a:  "ESC a <byte>"
'Se agrega testeo de cantidad de memoria para registro
'
'22/05/2014 - Ver: 1.7
'Se cambia la forma de setear los canales analógicos a:  "ESC a <byte>"
'
'24/05/2014 - Ver: 1.8
'Se acomoda rutinas de registro y se pasa T_reg de Byte a Word
'
'25/05/2014 - Ver: 1.9
'Se acomoda interrupciones en rutina de registro
'
'--------------------------------------------------------------
'Encabezado de compilación
'--------------------------------------------------------------
$regfile = "m1284pdef.dat"
$crystal = 12000000
$hwstack = 50
$swstack = 16
$framesize = 32
$baud = 57600
$lib "i2c_twi.lbx"                                          'Para usar I2C por hardware
'$sim                                                        'Para simular con el Bascom AVR

'--------------------------------------------------------------
'Declaración de llaves lógicas e compilación
'--------------------------------------------------------------
Const Pfail = 0                                             'Si se desea Power_Fail --> Pfail=1
Const Test = 0                                              'Si se desea testear los Stacks y Frames  -->  Test=1
Const Proteus = 0                                           'Si se desea simular con Proteus  -->  Proteus=1

'--------------------------------------------------------------
'Testing de stacks
'--------------------------------------------------------------
#if Test = 1
$lib "stackcheck.lib"
$hwcheck                                                    'hw stack check on
$framecheck
$softcheck
#endif

'--------------------------------------------------------------
'Declaración de constantes
'--------------------------------------------------------------
Const Veces_init = 2
Const Histeresis = 0.2
Const Equipo = "Proyecto - AD"
Const Modelo = "uP - ATMega1284p"
Const Ver_sion = "v 1.9"
Const Fecha = "25/05/2014"
Const Autor = "Autores: Lic. Lisandro Raviola / Ing. Gustavo Real"
Const Usuario = "UNGS"
'----                           Caracteres especiales de control
Const Cr = 13
Const Lf = 10
Const Esc = 27
Const Esp = 32
Const Acknn = 6
Const Bcksp = 8
Const Numeral = 35
Const Asterisco = 11
'----                           Caracteres ASCII números
Const Cero = 48
Const Uno = 49
Const Dos = 50
Const Tres = 51
Const Cuatro = 52
Const Cinco = 53
Const Seis = 54
Const Siete = 55
Const Ocho = 56
Const Nueve = 57
'----                           Caracteres ASCII letras mayúsculas
Const A_may = 65
Const B_may = 66
Const C_may = 67
Const D_may = 68
Const E_may = 69
Const F_may = 70
Const G_may = 71
Const H_may = 72
Const I_may = 73
Const J_may = 74
Const K_may = 75
Const L_may = 76
Const M_may = 77
Const N_may = 78
Const O_may = 79
Const P_may = 80
Const Q_may = 81
Const R_may = 82
Const S_may = 83
Const T_may = 84
Const U_may = 85
Const V_may = 86
Const W_may = 87
Const X_may = 88
Const Y_may = 89
Const Z_may = 90
'----                           Cracteres ASCII letras minúsculas
Const A_min = 97
Const B_min = 98
Const C_min = 99
Const D_min = 100
Const E_min = 101
Const F_min = 102
Const G_min = 103
Const H_min = 104
Const I_min = 105
Const J_min = 106
Const K_min = 107
Const L_min = 108
Const M_min = 109
Const N_min = 110
Const O_min = 111
Const P_min = 112
Const Q_min = 113
Const R_min = 114
Const S_min = 115
Const T_min = 116
Const U_min = 117
Const V_min = 118
Const W_min = 119
Const X_min = 120
Const Y_min = 121
Const Z_min = 122
'----
Const T0_start = 251                                        'Ya que -->  256-5=251 (Cuenta 5 y desborda el T0)
Const T1_start = 18661                                      'Ya que -->  65536-46875=18661 (Cuenta 46875 y desborda)
Const Max_canal = 8                                         'Máximo = 8
Const Rtc_ad = &HD0                                         'Direcciod del rtc en bus i2c
Const Rtc_m_st = &H08                                       'Dirección de comienzo ram rtc.
Const Mem_ad = &HA0                                         'Direcciod de la E2 en bus i2c
Const Mem_fin = 32767                                       'Fondo de la memoria EEprom

'--------------------------------------------------------------
'Declaración de variables internas en SRAM
'--------------------------------------------------------------
Dim Error As Bit
Dim Wd_flg As Bit                                           'Hubo un Reset por W_Dog  --> Wf_flg=1
Dim Esc_flg As Bit                                          'Se presionó la tecla ESC --> Esc_flg=1
Dim Tx_flg As Bit                                           'Transmisión contínua --> Tx_flg=1
Dim Mem_full As Bit                                         'EEProm llena --> Mem_full=1
'------
Dim Canal As Byte
Dim Cont_tm0 As Byte
Dim Bwd As Byte
Dim Keyread As Byte
Dim Ingreso As Byte
Dim Aux_b As Byte
Dim Com_in As Byte
Dim Cant_canal As Byte
Dim Cant_dig As Byte
Dim I As Byte
Dim I_it1 As Byte
Dim J As Byte
Dim K As Byte
Dim M As Byte
Dim Aux As Byte
Dim Aux2 As Byte
Dim Mes As Byte
Dim Dia As Byte
Dim Horas As Byte
Dim Minutos As Byte
Dim Segundos As Byte
Dim Min_int0 As Byte
Dim Seg_int0 As Byte
Dim Dem As Byte
Dim Cont1 As Byte
Dim Cont As Byte
Dim Punterobuffer As Byte
Dim Mchip As Byte                                           'indica en que chip estoy
Dim Memaddh As Byte
Dim Memaddl As Byte
Dim Gpsd As Byte
Dim Temp(4) As Byte
Dim Cmd As Byte
Dim Ss_tmp As Byte
Dim P_ss As Byte
Dim Gpsbuffer(80) As Byte
Dim V_temp_s(22) As Byte
Dim Reg_flg As Byte                                         'Habilitación de registro --> Reg_flg=1
'------
Dim Datos(8) As Word
Dim Aux_w As Word
Dim Espera As Word
Dim Parpadeo As Word
Dim W As Word
Dim Cont_seg As Word
Dim Set_seg As Word
Dim T_reg As Word
'------
Dim X As Integer
'------
Dim Datos_tx(8) As Long
Dim U1 As Long
Dim Pumem As Long
Dim Auxl As Long
'------
Dim Aux_s As Single
'------
Dim Buffprt As String * 24
Dim Aux_buff As String * 24

'--------------------------------------------------------------
'Declaración de variables internas en EEPROM
Dim E2can_ana As Eram Byte
Dim E2can_dig As Eram Byte
Dim E2reg_flg As Eram Byte
'------
Dim E2t_reg As Eram Word

'--------------------------------------------------------------
'Rutina que permite saber si se reseteó por W_dog
'--------------------------------------------------------------
'Bwd = Peek(0)
'If Bwd.wdrf = 1 Then
'   Wd_flg = 1
'Else
'   Wd_flg = 0
'End If

'--------------------------------------------------------------
'Declaración de config´s
'--------------------------------------------------------------
'Config Date = Dmy , Separator = /                           ' ANSI-Format
'Config Clock = Soft
'----
Config Scl = Portc.0
Config Sda = Portc.1
I2cinit
Config Twi = 100000                                         'Frecuencia clock SCL
'----
'Config Spi = Soft , Din = Pinb.6 , Dout = Portb.5 , Ss = Portb.4 , Clock = Portb.7
'----
Config Adc = Single , Prescaler = Auto , Reference = Off
Stop Adc
'----
Config Timer0 = Timer , Prescale = 256                      'Interrumpe --> 12000000/256/5=9375 (Frec/prescaler/timer0) int/seg
Stop Timer0                                                 'O sea, cada 107 useg
Timer0 = T0_start                                           'Ya que -->  256-5=251 (Cuenta 5 y desborda el T0)
'----
Config Timer1 = Timer , Prescale = 256                      'Interrumpe --> 12000000/256/46875=1seg (Frec/prescaler/timer0) int/seg
Stop Timer1                                                 'O sea, cada 107 useg
Timer1 = T1_start                                           'Ya que -->  256-5=251 (Cuenta 5 y desborda el T0)
'----
#if Pfail = 1
   Config Aci = On , Compare = Off , Trigger = Toggle
#endif
'----
'Config Watchdog = 2048                                      'Se resetea a los 2048 mSec (2 seg aprox.)

'--------------------------------------------------------------
'Configuración de ports
'--------------------------------------------------------------
'Config Pina.0 = Input
'Config Pina.1 = Input
'Config Pina.2 = Input
'Config Pina.3 = Input
'Config Pina.4 = Input
'Config Pina.5 = Input
'Config Pina.6 = Input
'Config Pina.7 = Input
'----
'Config Pinb.0 = Output
'Config Pinb.1 = Output
'Config Pinb.2 = Output
'Config Pinb.3 = Output
'Config Pinb.4 = Output
'Config Pinb.5 = Output
'Config Pinb.6 = Output
'Config Pinb.7 = Output
'----
'Config Pinc.0 = Output
'Config Pinc.1 = Output
Config Pinc.2 = Output
Config Pinc.3 = Output
'Config Pinc.4 = Output
'Config Pinc.5 = Output
'Config Pinc.6 = Output
'Config Pinc.7 = Output
'----
'Config Pind.0 = Output
'Config Pind.1 = Output
'Config Pind.2 = Output
'Config Pind.3 = Output
'Config Pind.4 = Output
'Config Pind.5 = Output
Config Pind.6 = Output
Config Pind.7 = Output

'--------------------------------------------------------------
'Declaración de subrutinas
Declare Sub Ini_var
Declare Sub Keyscan
Declare Sub Tx_rs232
Declare Sub Rx_rs232
Declare Sub Set_time
Declare Sub Get_time
Declare Sub Prt_time
Declare Sub Wr_rtc
Declare Sub Rd_rtc
Declare Sub Wr_e2
Declare Sub Rd_e2
Declare Sub Er_e2
Declare Sub Veri232_reloj
Declare Sub Mem_restante
Declare Sub Registro
Declare Sub Registroold
Declare Sub Graba_ini
Declare Sub Veri_ini

'--------------------------------------------------------------
'Declaración de Aliases
'Line_t Alias Portb.0                                        'para manejo del DS18B20 (Sensor Temp. 1-Wire
Testigo1 Alias Portd.6                                      'Led amarillo de Esc
Testigo2 Alias Portd.7                                      'Led rojo de 1seg
Wp Alias Portc.3                                            'Write protect eeprom
Buzzer Alias Portc.2

'--------------------------------------------------------------
'--------------------------------------------------------------
'COMIENZO DE PROGRAMA
'--------------------------------------------------------------
'--------------------------------------------------------------
Disable Interrupts

'If Wd_flg = 1 Then
'   Print "E00 - Reiniciado"
'   Wait 2
'End If

#if Proteus = 0
   Reset Buzzer
   Waitms 250
#endif
Set Buzzer

Print Equipo
Print Modelo
Print Ver_sion
Print Fecha
Print Autor
Print Usuario

Reset Testigo1
For I = 1 To 8
   Toggle Testigo1
   Waitms 250
Next I
Set Testigo1
Set Testigo2

Mchip = 0
Wp = 1

#if Pfail = 1
   On Aci P_fail Nosave
   Enable Aci , Hi
#endif

On Timer0 Int_timer0
Enable Timer0

On Timer1 Int_timer1
Enable Timer1

On Adc Int_adc
Enable Adc

On Serial Rx_rs232
Enable Serial

Call Ini_var

Start Adc
Set Adcsra.6

Enable Interrupts

'--------------------------------------------------------------
'RUTINA PRINCIPAL
'--------------------------------------------------------------

Do

   If Tx_flg = 1 Then Call Tx_rs232

Loop


'FIN RUTINA PRINCIPAL---------------------------------------

'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'----------------------SUBRRUTINAS------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'Subrutina inicialización básica del equipo
Sub Ini_var
   Call Veri232_reloj
   Call Veri_ini
   If Reg_flg = 1 Then Call Graba_ini
End Sub

'---------------------------------------------------------------------
'Rutina que verifica reloj en RS232
Sub Veri232_reloj
Local A As Byte

K = Rtc_m_st
Call Rd_rtc
If M <> Acknn Then
   Print "Reloj no inicializado"
Else
   Call Get_time
   Call Prt_time
End If
End Sub

'---------------------------------------------------------------------
'Rutina que verifica la inicializacion
Sub Veri_ini
   Cant_dig = E2can_dig
   Ddrb = Cant_dig

   Cant_canal = E2can_ana
   If Cant_canal < 1 Or Cant_canal > Max_canal Then
      Cant_canal = Max_canal
      E2can_ana = Cant_canal
   End If
   Canal = 0

   Reset Tx_flg
   Reset Esc_flg
   Reg_flg = E2reg_flg
   T_reg = E2t_reg

'   K = Rtc_m_st + 5
'   Call Rd_rtc
'   T_reg = M
   Pumem = 0
   K = Rtc_m_st + 4
   Call Rd_rtc
   Pumem = Pumem + M
   Shift Pumem , Left , 8
   K = Rtc_m_st + 3
   Call Rd_rtc
   Pumem = Pumem + M
   Shift Pumem , Left , 8
   K = Rtc_m_st + 2
   Call Rd_rtc
   Pumem = Pumem + M
   Shift Pumem , Left , 8
   K = Rtc_m_st + 1
   Call Rd_rtc
   Pumem = Pumem + M
   If Pumem < Mem_fin Then
      Reset Mem_full
   Else
      Set Mem_full
      Reg_flg = 0
      E2reg_flg = Reg_flg
   End If

   If Reg_flg = 1 Then Start Timer1
End Sub

'---------------------------------------------------------------------
'Rutina que graba inicializacion en memoria de registro
Sub Graba_ini
   M = &HFF                                                 'Marca de inicio
   Call Registro
   M = &HFF                                                 'Marca de inicio
   Call Registro
   Call Get_time
   For Aux2 = 1 To 10                                       'horas, minutos, segundos, día, mes
      M = Gpsbuffer(aux2)
      Call Registro
   Next
   M = &H32                                                 'año
   Call Registro
   M = &H30                                                 'año
   Call Registro
   M = Gpsbuffer(11)                                        'año
   Call Registro
   M = Gpsbuffer(12)                                        'año
   Call Registro
   M = Low(t_reg)                                           'Tiemoo de registro (low)
   Call Registro
   M = High(t_reg)                                          'Tiemoo de registro (high)
   Call Registro
   M = Cant_canal                                           'Cantidad de canales analógicos
   Call Registro
   M = Cant_dig                                             'Seteo de canales digitales (Entradas y Salidas)
   Call Registro
   K = Rtc_m_st + 6                                         'Código de inicio
   Call Rd_rtc
   M = &HFF                                                 'Marca de fin
   Call Registro
   M = &HFF                                                 'Marca de fin
   Call Registro
   K = Rtc_m_st + 6
   M = &H00
   Call Wr_rtc
End Sub

'---------------------------------------------------------------------
'Rutina que registra un byte (M) en E2 y guarda puntero en ram reloj (Pumem)
Sub Registroold

End Sub

Sub Registro
   Disable Adc
   Disable Timer0
   If Mem_full = 0 Then
      U1 = Pumem
      Call Wr_e2
      Incr Pumem
      Auxl = Pumem
      If Pumem >= Mem_fin Then
         Reg_flg = 0
         E2reg_flg = Reg_flg
         Set Mem_full
      End If
      K = Rtc_m_st + 1
      M = Auxl And &HFF
      Call Wr_rtc
      K = Rtc_m_st + 2
      Shift Auxl , Right , 8
      M = Auxl And &HFF
      Call Wr_rtc
      K = Rtc_m_st + 3
      Shift Auxl , Right , 8
      M = Auxl And &HFF
      Call Wr_rtc
      K = Rtc_m_st + 4
      Shift Auxl , Right , 8
      M = Auxl And &HFF
      Call Wr_rtc
   End If
   Enable Timer0
   Enable Adc
End Sub

'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------------------------- E2prom ---------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'  ingresa direccion en U1, elijo chip en Mchip y dato en M
Sub Wr_e2
  I = Mem_ad
  I = I Or Mchip
  Memaddl = U1 And &HFF
  Rotate U1 , Right , 8
  Memaddh = U1 And &HFF
  Wp = 0
  I2cstart
  I2cwbyte I
  I2cwbyte Memaddh
  I2cwbyte Memaddl
  I2cwbyte M
  I2cstop
'  Waitms 10
  Wp = 1
End Sub

'-----------------------------------------------------------
'  ingresa direccion en U1, elijo chip en Mchip y devuelve dato en M
Sub Rd_e2
  I = Mem_ad
  I = I Or Mchip
  Memaddl = U1 And &HFF
  Rotate U1 , Right , 8
  Memaddh = U1 And &HFF
  I2cstart
  I2cwbyte I
  I2cwbyte Memaddh
  I2cwbyte Memaddl
  I2cstart
  Incr I
  I2cwbyte I
  I2crbyte M , 9
  I2cstop
End Sub

'---- borrado rapido de eeprom ---------
Sub Er_e2
  I = Mem_ad
  I = I Or Mchip
  M = &HFF
  Wp = 0
  U1 = 0
  Do
'    lcall wdog
    Auxl = U1
    Memaddl = Auxl And &HFF
    Rotate Auxl , Right , 8
    Memaddh = Auxl And &HFF
    I2cstart
    I2cwbyte I
    I2cwbyte Memaddh
    I2cwbyte Memaddl
    K = 0
    Do
      I2cwbyte M
      Incr K
      Incr U1
    Loop Until K = 64
    I2cstop
    Waitms 10
    Toggle Testigo1
    If U1 > Mem_fin Then Exit Do
  Loop
  Wp = 1
End Sub

'---------------------------------------------------------------------
'--------------------------------------------------
'---------- Subrutinas del reloj DS1307 -----------
'--------------------------------------------------
'---------------------------------------------------------------------
'Seteo del reloj
Sub Set_time
'hhmmssddmmaaaa  invierto ssmmhhddmmaaaa
  K = Gpsbuffer(1)
  Gpsbuffer(1) = Gpsbuffer(5)
  Gpsbuffer(5) = K
  K = Gpsbuffer(2)
  Gpsbuffer(2) = Gpsbuffer(6)
  Gpsbuffer(6) = K
  K = 0
  Do
    Incr K
    I = K
    Incr I
    M = Gpsbuffer(k) * 10
    M = M + Gpsbuffer(i)
    Select Case K
'ss - mm
      Case Is < 4:
        If M > 59 Then Goto Salgo
'hh
      Case 5:
        If M > 23 Then Goto Salgo
'dd
      Case 7:
        If M > 31 Then Goto Salgo
        If M = 0 Then Goto Salgo
'mm
      Case 9:
        If M > 12 Then Goto Salgo
        If M = 0 Then Goto Salgo
'año 20
      Case 11:
        If M <> 20 Then Goto Salgo
'año 02
      Case 13:
        If M > 99 Then Goto Salgo
        If M < 0 Then Goto Salgo
    End Select
    Incr K
  Loop Until K = 14
  K = 0
  Do
    Incr K
    I = Gpsbuffer(k)
    Rotate I , Left , 4
    Incr K
    M = Gpsbuffer(k)
    Gpsbuffer(k) = I Or M
  Loop Until K > 13

'programar a ds1307
'SETEO SS MM HH DD MM
  K = 0
  I = Rtc_ad
  M = &H80
  I2cstart
  I2cwbyte I
  I2cwbyte K
  I2cwbyte M
  I2cstop
  J = 4
  K = 1
  I = Rtc_ad
  Do
    M = Gpsbuffer(j)
    I2cstart
    I2cwbyte I
    I2cwbyte K
    I2cwbyte M
    I2cstop
    Incr J
    Incr J
    Incr K
    If K = 3 Then Incr K
    If K = 6 Then
      Incr J
      Incr J
    End If
  Loop Until K = 7
  K = 0
  M = Gpsbuffer(2)
  I2cstart
  I2cwbyte I
  I2cwbyte K
  I2cwbyte M
  I2cstop
  Error = 0
  Goto Stfin
Salgo:
  Error = 1
Stfin:
End Sub

'-----------------------------------------------------------
' --------   leo ds1307 SS MM HH DD MM AA AA
Sub Get_time
  Disable Timer0
  J = 1
  K = 0
  I = Rtc_ad
  I2cstart
  I2cwbyte I
  I2cwbyte K
  I2cstart
  Incr I
  I2cwbyte I
  Do
    I2crbyte M , 8
    If K <> 3 Then
      I = M And &H0F
      I = I + 48
      Rotate M , Right , 4
      M = M And &H0F
      M = M + 48
      Gpsbuffer(j) = M
      Incr J
      Gpsbuffer(j) = I
      Incr J
    End If
    Incr K
  Loop Until K = 6
  I2crbyte M , 9
  I = M And &H0F
  I = I + 48
  Rotate M , Right , 4
  M = M And &H0F
  M = M + 48
  Gpsbuffer(j) = M
  Incr J
  Gpsbuffer(j) = I
  I2cstop
'hhmmssddmmaaaa  invierto ssmmhhddmmaaaa
  K = Gpsbuffer(1)
  Gpsbuffer(1) = Gpsbuffer(5)
  Gpsbuffer(5) = K
  K = Gpsbuffer(2)
  Gpsbuffer(2) = Gpsbuffer(6)
  Gpsbuffer(6) = K
  Enable Timer0
End Sub

'-----------------------------------------------------------
Sub Prt_time
'  Print "Reloj: ";
  K = 0
  Do
    Incr K
    I = K
    Incr I
    If K = 11 Then Print "20" ;
    Buffprt = Chr(gpsbuffer(k))
    Print Buffprt;
    Buffprt = Chr(gpsbuffer(i))
    Print Buffprt;
    Select Case K
       Case 1:
         Print ":";
       Case 3:
         Print ":";
       Case 5:
         Print " ";
       Case 7:
         Print "/";
       Case 9:
         Print "/";
    End Select
    Incr K
  Loop Until K > 11
  Print
End Sub

'-----------------------------------------------------------
'  ingresa direccion en k, elijo chip en I y dato en M
Sub Wr_rtc
  I = Rtc_ad
  I2cstart
  I2cwbyte I
  I2cwbyte K
  I2cwbyte M
  I2cstop
End Sub

'-----------------------------------------------------------
'  ingresa direccion en k, elijo chip en I y devuelve dato en M
Sub Rd_rtc
  I = Rtc_ad
  I2cstart
  I2cwbyte I
  I2cwbyte K
  I2cstart
  Incr I
  I2cwbyte I
  I2crbyte M , 9
  I2cstop
End Sub

'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------- Subrutinas de interacción con el equipo ------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'Rutina que transmite los datos de los canales analógicos seteados por RS232
Sub Tx_rs232
   Local I As Byte
   For I = 1 To Cant_canal
      Aux_w = Datos(i)
      Printbin Aux_w
   Next I
End Sub

'---------------------------------------------------------------------
'Rutina que calcula memoria restante y utilizada
Sub Mem_restante
   Print "Memoria utilizada --> " ; Pumem ; " bytes"
   U1 = Mem_fin - Pumem
   Print "Memoria restante ---> " ; U1 ; " bytes"
End Sub

'---------------------------------------------------------------------
'---------------------------------------------------------------------
'----------------------INTERRUPCIONES---------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
Int_timer0:
   Stop Timer0
   Timer0 = T0_start
   Set Adcsra.6                                             'Activa conversión
Return

'---------------------------------------------------------------------
Int_timer1:
   Timer1 = T1_start
   Toggle Testigo2
   Incr Cont_seg
   If Cont_seg = T_reg Then
      Cont_seg = 0
      For I_it1 = 1 To Cant_canal
         M = Low(datos(i_it1))
         Call Registro
         M = High(datos(i_it1))
         Call Registro
      Next I_it1
   End If
Return

'---------------------------------------------------------------------
Int_adc:
   Aux_b = Adcl
   Datos(canal + 1) = Adch
   Shift Datos(canal + 1) , Left , 8
   Datos(canal + 1) = Datos(canal + 1) + Aux_b
   Incr Canal
   If Canal >= Cant_canal Then Canal = 0
   Aux_b = Admux
   Aux_b = Aux_b And &HF8
   Aux_b = Aux_b + Canal
   Admux = Aux_b
   Start Timer0
Return

'---------------------------------------------------------------------
'Rutina que recibe datos por el port serial en "Com"
Rx_rs232:
   Com_in = Inkey()
   If Com_in <> 0 Then
      If Com_in = Esc Then
         If Esc_flg = 0 Then
            Set Esc_flg
            Reset Testigo1
         Else
            Reset Esc_flg
            Set Testigo1
         End If
      Else
         If Esc_flg = 1 Then
            Reset Esc_flg
            Select Case Com_in
#if Test = 1
               Case Cero:                                   'Testeo de stacks y frame  -->  "ESC 0"
                  Print
                  W = _hwstackstart - _hw_lowest
                  Print "HW stack recomendado:    " ; W
                  W = _hwstack_low - _sw_lowest
                  Print "SW stack recomendado:    " ; W
                  If _fw_highest > 0 Then
                     W = _frame_high - _fw_highest
                     Print "Frame space recomendado: " ; W
                  End If
                  Print
               Case Uno:                                    'Graba y lee un dato en la E2  -->  "ESC 1"
                  Print
                  Input "Ingrese el dato numerico: " , M
                  Input "Ingrese la direccion: " , Auxl
                  Print
                  Print "Dato escrito: " ; M
                  U1 = Auxl
                  Call Wr_e2
                  M = 0
                  U1 = Auxl
                  Call Rd_e2
                  Print "Dato leido: " ; M
                  Print
#endif
               Case A_may:                                  'Recibe cantidad de canales analógicos
                  Com_in = Waitkey()                        'ESC A <num>  || <num> de 1 a 8
                  If Com_in > 48 And Com_in < 57 Then
                     Cant_canal = Com_in - 48
                     E2can_ana = Cant_canal
                     Canal = 0
                  End If
'                  Printbin Acknn
               Case B_may:                                  'Recibe tiempo de registro en segundos
                  Input Aux_w                               ' "ESC B <num> 0D 0A" || <num> de 1 a 65535
                  If Aux_w > 0 And Aux_w < 65536 Then
                     T_reg = Aux_w
                     E2t_reg = T_reg
                  End If
'                  Printbin Acknn
               Case D_may:                                  'Recibe el seteo del sentido de los canales digitales (1=SAL, 0=ENT) --> "ESC S" <byte>
                  Cant_dig = Waitkey()
                  Ddrb = Cant_dig
                  E2can_dig = Cant_dig
'                  Printbin Acknn
               Case H_may:                                  'Seteo de hora  -->  "ESC H hhmmssDDMMAAAA"
                  For K = 1 To 14
                     I = Waitkey()
                     I = I - 48
                     Gpsbuffer(k) = I
                  Next K
                  Call Set_time
                  M = Acknn
                  K = Rtc_m_st
                  Call Wr_rtc
'                  Printbin Acknn
               Case I_may:                                  'Borrado de memoria y Treg = 5seg --> "ESC I"
                  Disable Interrupts
                  Reg_flg = 0
                  E2reg_flg = Reg_flg
                  T_reg = 60                                'Tiempo de registro default --> 60seg
                  E2t_reg = T_reg
                  Print "Borrando memoria..."
#if Proteus = 0
                  Call Er_e2
#endif
                  Print "Inicializando..."
                  Pumem = 0
                  Auxl = Pumem
                  K = Rtc_m_st + 1
                  M = Auxl And &HFF
                  Call Wr_rtc
                  K = Rtc_m_st + 2
                  Shift Auxl , Right , 8
                  M = Auxl And &HFF
                  Call Wr_rtc
                  K = Rtc_m_st + 3
                  Shift Auxl , Right , 8
                  M = Auxl And &HFF
                  Call Wr_rtc
                  K = Rtc_m_st + 4
                  Shift Auxl , Right , 8
                  M = Auxl And &HFF
                  Call Wr_rtc
                  K = Rtc_m_st + 6
                  M = &H01
                  Call Wr_rtc
                  Call Ini_var
                  Enable Interrupts
               Case R_may:                                  'Habilita/Deshabilita registro  -->  "Esc R"
                  If Reg_flg = 1 Then
                     Reg_flg = 0
                     E2reg_flg = Reg_flg
                     Stop Timer1
                     Set Testigo2
                  Else
                     Reg_flg = 1
                     E2reg_flg = Reg_flg
                     K = Rtc_m_st + 6
                     M = &H07
                     Call Wr_rtc
                     Call Ini_var
                     Timer1 = T1_start
                     Cont_seg = 0
                     Start Timer1
                  End If
               Case S_may:                                  'Setea las salidas de acuerdo a lo que recibe por RS232 --> "ESC S <byte>"
                  Com_in = Waitkey()
                  Portb = Ddrb And Com_in
'                  Printbin Acknn
               Case T_may:                                  'Habilita/Deshabilita transmisión de datos --> "ESC T"
                  If Tx_flg = 0 Then
                     Set Tx_flg
                  Else
                     Reset Tx_flg
                  End If
               Case A_min:                                  'Transmite datos de todos los canales analógicos steteados -->  "ESC a"
                  Call Tx_rs232
               Case B_min :                                 'transmite El Canal Analógico Solicitado - - > "Esc b <byte>"
                  Com_in = Waitkey()                        '|| < Byte > De 1 A 8 ""
                  I = Com_in - 48
                  Aux_w = Datos(i)
                  Printbin Aux_w
               Case D_min:                                  'Transmite estados de los 8 canales digitales --> "ESC d" y devuelve <byte>
                  Printbin Pinb
               Case E_min:                                  'Transmite datos del equipo  -->  "ESC e" y devuelve los datos del equipo
                  Print Equipo
                  Print Modelo
                  Print Ver_sion
                  Print Fecha
                  Print Autor
                  Print Usuario
               Case H_min:                                  'Ver reloj  -->  "ESC h"
                  Call Get_time
                  Call Prt_time
               Case M_min:                                  'Ver memoria utilizada y restante: --> "ESC m"
                  Call Mem_restante
               Case Else:
                  nop
            End Select
            Set Testigo1
         Else
            Printbin Com_in
         End If
      End If
   End If
Return

'---------------------------------------------------------------------
'---------------------------------------------------------------------
'----------------------RUTINAS ESPECIALES-----------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'Rutina de Power Fail - Para interrupciones y guarda el tiempo transcurrido
#if Pfail = 1
P_fail:
   Disable Interrupts
   Do
   Loop
Return
#endif

'---------------------------------------------------------------------

End