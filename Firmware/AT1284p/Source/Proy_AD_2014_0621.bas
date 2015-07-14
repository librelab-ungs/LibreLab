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
'07/06/2014 - Ver: 2.0
'Se comienza a programar el modo "Burst"
'Disparado externamente o por la PC
'
'08/06/2014 - Ver: 2.1
'Se agrega la descarga y el help de los comandos
'
'14/06/2014 - Ver: 2.2
'Se puso compilación condicional para up ATMega2560
'
'20/06/2014 - Ver: 2.3
'Se saca compilación condicional para up ATmega2560
'Se agrega versionado automático
'
'21/06/2014 - Ver: 2.4
'Se corrigen temas de registro de los eventos
'
'--------------------------------------------------------------
'Declaración de llaves lógicas e compilación
'--------------------------------------------------------------
Const Pfail = 0                                             'Si se desea Power_Fail --> Pfail=1
Const Test = 0                                              'Si se desea testear los Stacks y Frames  -->  Test=1
Const Proteus = 1                                           'Si se desea simular con Proteus  -->  Proteus=1

'--------------------------------------------------------------
'Encabezado de compilación
'--------------------------------------------------------------
$regfile = "m1284pdef.dat"
$crystal = 12000000
'$regfile = "m2560def.dat"
'$crystal = 16000000

$hwstack = 48
$swstack = 16
$framesize = 32
$version 2,4,7

#if Proteus = 1
   $baud = 19200
#else
   $baud = 57600
#endif

$lib "i2c_twi.lbx"                                          'Para usar I2C por hardware
'$sim                                                        'Para simular con el Bascom AVR

'--------------------------------------------------------------
'Testing de stacks
'--------------------------------------------------------------
#if Test = 1
   $lib "stackcheck.lib"
   $hwcheck                                                 'hw stack check on
   $framecheck
   $softcheck
#endif

'--------------------------------------------------------------
'Declaración de constantes
'--------------------------------------------------------------
Const Veces_init = 2
Const Histeresis = 0.2
Const Equipo = "Proyecto: AD"
Const Modulo = "Equipo:   AQC01"
Const Fecha = "Fecha:    21/06/2014"
Const Autor = "Autores:  Lic. Lisandro Raviola / Ing. Gustavo Real"
Const Usuario = "Usuario:  UNGS"
'----                           Caracteres especiales de control
Const Acknn = 6
Const Bcksp = 8
Const Lf = 10
Const Cr = 13
Const Naknn = 21
Const Esc = 27
Const Esp = 32
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
Const T0_start = 253                                        'Ya que -->  256-3=253 (Cuenta 3 y desborda el T0)
Const T1_start1 = 18661                                     'Ya que -->  65536-46875=18661 (Cuenta 46875 y desborda el T1)
Const T1_start2 = 64336                                     'Ya que -->  65536-1200=64336 (Cuenta 1200 y desborda el T1)
Const Max_canal = 8                                         'Máximo = 8
Const Rtc_ad = &HD0                                         'Direcciod del rtc en bus i2c
Const Rtc_m_st = &H08                                       'Dirección de comienzo ram rtc.
Const Mem_ad = &HA0                                         'Direcciod de la E2 en bus i2c
Const Mem_fin = 32767                                       'Fondo de la memoria EEprom
Const Buff_max = 2048                                       'Largo del buffer para Burst
Const Buff_max_8 = Buff_max - 8

'--------------------------------------------------------------
'Declaración de variables internas en SRAM
'--------------------------------------------------------------
Dim Wd_flg As Bit                                           'Hubo un Reset por W_Dog  --> Wf_flg=1
Dim Esc_flg As Bit                                          'Se presionó la tecla ESC --> Esc_flg=1
Dim Tx_flg As Bit                                           'Transmisión contínua --> Tx_flg=1
Dim Mem_full As Bit                                         'EEProm llena --> Mem_full=1
Dim Bst_flg As Bit                                          'Modo burst  --> Bst_flg=1
Dim Bst_listo As Bit                                        'Tabla llena y lista para enviar
Dim Cold_flg As Bit
'------
Dim Error As Byte                                           ' "0"=no importa || "A"=Ack  ||  "N"=Nak
Dim Canal As Byte
Dim Bwd As Byte
Dim Aux_b As Byte
Dim Com_in As Byte
Dim Cant_canal As Byte
Dim Cant_dig As Byte
Dim I As Byte
Dim I_it1 As Byte
Dim J As Byte
Dim K As Byte
Dim M As Byte
Dim Aux2 As Byte
Dim Mchip As Byte                                           'indica en que chip estoy
Dim Memaddh As Byte
Dim Memaddl As Byte
Dim Gpsbuffer(80) As Byte
Dim Reg_flg As Byte                                         'Habilitación de registro --> Reg_flg=1
Dim Trigger As Byte
'------
Dim Datos(8) As Word
Dim W As Word
Dim Aux_w As Word
Dim Aux_i As Word
Dim Cont_tmp As Word
Dim T_reg As Word
Dim Intervalo As Word
Dim Buff_bst(buff_max) As Word
Dim Punt_wr As Word
Dim Aux_punt As Word
'------
Dim U1 As Long
Dim Pumem As Long
Dim Aux_l As Long
'------
Dim Buffprt As String * 24

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
'   Bwd = Peek(0)
'   If Bwd.wdrf = 1 Then
'   Wd_flg = 1
'   Else
'   Wd_flg = 0
'   End If

'--------------------------------------------------------------
'Declaración de config´s
'--------------------------------------------------------------
   Config Scl = Portc.0
   Config Sda = Portc.1
'   Config Scl = Portd.0
'   Config Sda = Portd.1
I2cinit
Config Twi = 100000                                         'Frecuencia clock SCL
'----
'Config Spi = Soft , Din = Pinb.6 , Dout = Portb.5 , Ss = Portb.4 , Clock = Portb.7
'----
Config Adc = Single , Prescaler = Auto , Reference = Off
Stop Adc
'----
Config Timer0 = Timer , Prescale = 256                      'Interrumpe --> 12000000/256/3=15625 (Frec/prescaler/timer0) int/seg
Stop Timer0                                                 'O sea, cada 64 useg
Timer0 = T0_start                                           'Ya que -->  256-3=253 (Cuenta 3 y desborda el T0)
'----
Config Timer1 = Timer , Prescale = 256                      'Interrumpe --> 12000000/256/46875=1 (Frec/prescaler/timer0) int/seg
Stop Timer1                                                 'O sea, cada 1 seg
Timer1 = T1_start1                                          'Ya que -->  65636-46875=18661 (Cuenta 46875 y desborda el T1)
'----
#if Pfail = 1
   Config Aci = On , Compare = Off , Trigger = Toggle
#endif
'----
'Config Watchdog = 2048                                      'Se resetea a los 2048 mSec (2 seg aprox.)

'--------------------------------------------------------------
'Configuración de ports y alias
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
'----
   Testigo1 Alias Portd.6                                   'Led de Esc
   Testigo2 Alias Portd.7                                   'Led de 1seg
   Wp Alias Portc.3                                         'Write protect eeprom
   Buzzer Alias Portc.2
'------------------------
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
'   Config Pinb.7 = Output
   '----
   'Config Pinc.0 = Output
'   Config Pinc.1 = Output
'   Config Pinc.2 = Output
'   Config Pinc.3 = Output
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
   'Config Pind.6 = Output
   'Config Pind.7 = Output
'----
'   Testigo1 Alias Portb.7                                   'Led amarillo de Esc
'   Testigo2 Alias Portc.1                                   'Led rojo de 1seg
'   Wp Alias Portc.3                                         'Write protect eeprom
'   Buzzer Alias Portc.2

'--------------------------------------------------------------
'Declaración de subrutinas
Declare Sub Ini_var
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
Declare Sub Graba_ini
Declare Sub Veri_ini
Declare Sub Parada
Declare Sub Cfg_int0
Declare Sub Prt_help_com

'--------------------------------------------------------------
'--------------------------------------------------------------
'COMIENZO DE PROGRAMA
'--------------------------------------------------------------
'--------------------------------------------------------------
Disable Interrupts
Set Cold_flg

'If Wd_flg = 1 Then
'   Print "E00 - Reiniciado"
'   Wait 2
'End If

#if Proteus = 0
   Reset Buzzer
   Waitms 250
#else
   Print Equipo
   Print Modulo
#endif

Set Buzzer

Reset Testigo1
For I = 1 To 8
   Toggle Testigo1
   Waitms 250
Next I

Call Parada

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

On Int0 Int_int0

Call Ini_var

Start Adc
Set Adcsra.6

Reset Cold_flg
Enable Interrupts

'--------------------------------------------------------------
'RUTINA PRINCIPAL
'--------------------------------------------------------------

Do

   If Tx_flg = 1 Then Call Tx_rs232

   If Bst_listo = 1 Then
      Reset Bst_listo
      For Aux_i = 1 To Aux_punt
         Aux_w = Buff_bst(aux_i)
         Printbin Aux_w
      Next Aux_i
   End If

Loop


'FIN RUTINA PRINCIPAL---------------------------------------

'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'----------------------SUBRRUTINAS------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'Rutina que para actividad del equipo, solo escucha RS232
Sub Parada
   Stop Timer1
   Reset Tx_flg
   Reset Esc_flg
   Reg_flg = 0
   Cont_tmp = 0
   Reset Bst_flg
   Reset Bst_listo
   Set Testigo1
   Set Testigo2
End Sub

'---------------------------------------------------------------------
'Subrutina inicialización básica del equipo
Sub Ini_var
   Call Veri232_reloj
   Call Veri_ini
   If Cold_flg = 1 And Reg_flg = 0 Then
      nop
   Else
      Call Graba_ini
   End If
   If Reg_flg = 1 Then Start Timer1
'   Call Get_time
'   Call Prt_time
End Sub

'---------------------------------------------------------------------
'Rutina que verifica reloj
Sub Veri232_reloj
   Local A As Byte

   K = Rtc_m_st
   Call Rd_rtc
   If M <> Acknn Then
      Call Parada
      Print "Reloj no inicializado"
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
'   M = Cant_dig                                             'Seteo de canales digitales (Entradas y Salidas)
'   Call Registro
   K = Rtc_m_st + 6                                         'Código de inicio
   Call Rd_rtc
   Call Registro
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
Sub Registro
   Disable Adc
   Stop Timer0
   If Mem_full = 0 Then
      U1 = Pumem
      Call Wr_e2
      Incr Pumem
      Aux_l = Pumem
      If Pumem >= Mem_fin Then
         Reg_flg = 0
         E2reg_flg = Reg_flg
         Set Mem_full
      End If
      K = Rtc_m_st + 1
      M = Aux_l And &HFF
      Call Wr_rtc
      K = Rtc_m_st + 2
      Shift Aux_l , Right , 8
      M = Aux_l And &HFF
      Call Wr_rtc
      K = Rtc_m_st + 3
      Shift Aux_l , Right , 8
      M = Aux_l And &HFF
      Call Wr_rtc
      K = Rtc_m_st + 4
      Shift Aux_l , Right , 8
      M = Aux_l And &HFF
      Call Wr_rtc
   End If
   Start Timer0
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
   Waitms 10
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
      Aux_l = U1
      Memaddl = Aux_l And &HFF
      Rotate Aux_l , Right , 8
      Memaddh = Aux_l And &HFF
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
End Sub

'-----------------------------------------------------------
Sub Prt_time
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
'Configura Int0 de acuerdo a lo enviado por la PC
Sub Cfg_int0
   Disable Int0
   If Trigger = "F" Then
      Config Int0 = Falling
      Enable Int0
   End If
   If Trigger = "R" Then
      Config Int0 = Rising
      Enable Int0
   End If
End Sub

'---------------------------------------------------------------------
'Rutina que imprime el "Help"
Sub Prt_help_com
   Print
   Print "Bienvenido a la ayuda de comandos"
   Print
   Print "ESC 0 --> Testeo de stacks y frame"
   Print
   Print "ESC 1 --> Graba y lee un dato en la E2"
   Print
   Print "ESC 9 <char> --> Eco de un caracter cualquiera"
   Print
   Print "ESC A <num> --> Recibe cantidad de canales analógicos: <num> de 1 a 8"
   Print
   Print "ESC B <num> 0D 0A --> Recibe tiempo de registro en segundos: <num> de 1 a 65535"
   Print
   Print "ESC S <byte> --> Recibe el seteo del sentido de los canales digitales (1=SAL, 0=ENT)"
   Print
   Print "ESC H hhmmssDDMMAAAA --> Seteo de hora"
   Print
   Print "ESC I --> Borrado de memoria y Treg = 5seg || Tiempo de registro default: 60seg"
   Print
   Print "ESC O <trigger> <intervalo> --> Modo Burst"
   Print "      Trigger: 'R'=Int0/rising edge || 'F'=Int0/falling || 'P'=PC"
   Print "      Intervalo: x100us  0D 0A"
   Print
   Print "ESC P --> Parada del equipo --> No hace nada, solo escuchar la RS232"
   Print
   Print "Esc R --> Habilita/Deshabilita registro"
   Print
   Print "ESC S <byte> --> Setea las salidas de acuerdo a lo que recibe por RS232"
   Print
   Print "ESC T --> Habilita/Deshabilita transmisión de datos continuo"
   Print
   Print "ESC a --> Transmite datos de todos los canales analógicos steteados"
   Print
   Print "Esc b <byte> --> Transmite el Canal Analógico Solicitado || < Byte > De 1 A 8 "
   Print
   Print "ESC c y devuelve <byte> --> Transmite estados de los 8 canales digitales"
   Print
   Print "ESC d --> Descarga de datos binaria"
   Print
   Print "ESC e y devuelve los datos del equipo --> Transmite datos del equipo"
   Print
   Print "ESC f --> Ver lista de comandos"
   Print
   Print "ESC h --> Ver reloj"
   Print
   Print "ESC m --> Ver memoria utilizada y restante"
   Print
   Print "ESC t --> Trigger para Burst"
   Print
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
   If Reg_flg = 1 Then
      Timer1 = T1_start1
      Toggle Testigo2
      Incr Cont_tmp
      If Cont_tmp = T_reg Then
         Cont_tmp = 0
         For I_it1 = 1 To Cant_canal
            M = Low(datos(i_it1))
            Call Registro
            M = High(datos(i_it1))
            Call Registro
         Next I_it1
      End If
   Else
      Timer1 = T1_start2
      Toggle Testigo2
      Incr Cont_tmp
      If Cont_tmp = Intervalo Then
         Cont_tmp = 0
         If Punt_wr < Buff_max_8 Then
            For I_it1 = 1 To Cant_canal
               Buff_bst(punt_wr) = Datos(i_it1)
               Incr Punt_wr
            Next I_it1
         Else
            Stop Timer1
            Aux_punt = Punt_wr - 1
            Punt_wr = 1
            Set Bst_listo
         End If
      End If
   End If
Return

'---------------------------------------------------------------------
Int_adc:
   Aux_b = Adcl
   Datos(canal + 1) = Adch
   If Aux_b = &HFF Then Aux_b = &HFE
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
Int_int0:
   If Bst_flg = 1 Then
      Cont_tmp = 0
      Timer1 = T1_start2
      Start Timer1
   End If
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
            Error = 0
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
            #endif
               Case Uno:                                    'Graba y lee un dato en la E2  -->  "ESC 1"
                  Print
                  Input "Ingrese el dato numerico: " , M
                  Input "Ingrese la direccion: " , Aux_l
                  Print
                  Print "Dato escrito: " ; M
                  U1 = Aux_l
                  Call Wr_e2
                  M = 0
                  U1 = Aux_l
                  Call Rd_e2
                  Print "Dato leido: " ; M
                  Print
            Case Nueve:                                     'Eco de un caracter cualquiera
               Com_in = Waitkey()
               Printbin Com_in
            Case A_may:                                     'Recibe cantidad de canales analógicos
               Com_in = Waitkey()                           'ESC A <num>  || <num> de 1 a 8
               If Com_in > 48 And Com_in < 57 Then
                  Cant_canal = Com_in - 48
                  E2can_ana = Cant_canal
                  Canal = 0
               End If
               K = Rtc_m_st + 6
               M = &H09
               Call Wr_rtc
               Call Ini_var
               'Error = "A"
            Case B_may:                                     'Recibe tiempo de registro en segundos
               Input Aux_w                                  ' "ESC B <num> 0D 0A" || <num> de 1 a 65535
               If Aux_w > 0 And Aux_w < 65536 Then
                  T_reg = Aux_w
                  E2t_reg = T_reg
               End If
               K = Rtc_m_st + 6
               M = &H02
               Call Wr_rtc
               Call Ini_var
               'Error = "A"
            Case D_may:                                     'Recibe el seteo del sentido de los canales digitales (1=SAL, 0=ENT) --> "ESC S" <byte>
               Cant_dig = Waitkey()
               Ddrb = Cant_dig
               E2can_dig = Cant_dig
               'Error = "A"
            Case H_may:                                     'Seteo de hora  -->  "ESC H hhmmssDDMMAAAA"
               For K = 1 To 14
                  I = Waitkey()
                  I = I - 48
                  Gpsbuffer(k) = I
               Next K
               Call Set_time
               M = Acknn
               K = Rtc_m_st
               Call Wr_rtc
               K = Rtc_m_st + 6
               M = &H05
               Call Wr_rtc
               Call Ini_var
               'Error = "A"
            Case I_may:                                     'Borrado de memoria y Treg = 5seg --> "ESC I"
               Disable Interrupts
               Reg_flg = 0
               E2reg_flg = Reg_flg
               T_reg = 10                                   'Tiempo de registro default --> 10seg
               E2t_reg = T_reg
               'Print "Borrando memoria..."
               #if Proteus = 0
                  Call Er_e2
               #endif
               'Print "Inicializando..."
               Pumem = 0
               Aux_l = Pumem
               K = Rtc_m_st + 1
               M = Aux_l And &HFF
               Call Wr_rtc
               K = Rtc_m_st + 2
               Shift Aux_l , Right , 8
               M = Aux_l And &HFF
               Call Wr_rtc
               K = Rtc_m_st + 3
               Shift Aux_l , Right , 8
               M = Aux_l And &HFF
               Call Wr_rtc
               K = Rtc_m_st + 4
               Shift Aux_l , Right , 8
               M = Aux_l And &HFF
               Call Wr_rtc
               K = Rtc_m_st + 6
               M = &H01
               Call Wr_rtc
               Call Ini_var
               Enable Interrupts
               'Error = "A"
            Case O_may                                      'modo Burst --> "ESC O <trigger> <intervalo>"
               Call Parada
               Trigger = Waitkey()                          'Trigger: "R"=Int0/rising edge || "F"=Int0/falling || "P"=PC
               Input Intervalo                              'Intervalo: x100us  0D 0A
               Set Bst_flg
               Punt_wr = 1
               Config Timer1 = Timer , Prescale = 1         'Interrumpe --> 12000000/1/1200=10000 (Frec/prescaler/timer1) int/seg
               Stop Timer1                                  'O sea, cada 100 useg
               Timer1 = T1_start2                           'Ya que -->  65536-1200=64336 (Cuenta 1200 y desborda el T1)
               Call Cfg_int0
               'Error = "A"
            Case P_may:                                     'Parada del equipo --> No hace nada, solo escuchar la RS232
               Call Parada
               'Error = "A"
            Case R_may:                                     'Habilita/Deshabilita registro  -->  "Esc R"
               If Reg_flg = 1 Then
                  Call Parada
                  E2reg_flg = Reg_flg
               Else
                  Config Timer1 = Timer , Prescale = 256    'Interrumpe --> 12000000/256/46875=1 (Frec/prescaler/timer1) int/seg
                  Stop Timer1                               'O sea, cada 1 seg
                  Timer1 = T1_start1                        'Ya que -->  65636-46875=18661 (Cuenta 46875 y desborda el T1)
                  Reg_flg = 1
                  E2reg_flg = Reg_flg
                  K = Rtc_m_st + 6
                  M = &H08
                  Call Wr_rtc
                  Call Ini_var
                  Cont_tmp = 0
                  Start Timer1
               End If
               'Error = "A"
            Case S_may:                                     'Setea las salidas de acuerdo a lo que recibe por RS232 --> "ESC S <byte>"
               Com_in = Waitkey()
               Portb = Ddrb And Com_in
               'Error = "A"
            Case T_may:                                     'Habilita/Deshabilita transmisión de datos continuo --> "ESC T"
               If Tx_flg = 0 Then
                  Set Tx_flg
               Else
                  Call Parada
               End If
            Case A_min:                                     'Transmite datos de todos los canales analógicos steteados -->  "ESC a"
               Call Tx_rs232
            Case B_min :                                    'transmite El Canal Analógico Solicitado - - > "Esc b <byte>"
               Com_in = Waitkey()                           '|| < Byte > De 1 A 8 ""
               I = Com_in - 48
               Aux_w = Datos(i)
               Printbin Aux_w
            Case C_min:                                     'Transmite estados de los 8 canales digitales --> "ESC c" y devuelve <byte>
               Printbin Pinb
            Case D_min:                                     'Descarga de datos binaria --> "ESC d"
               Stop Timer1
               Stop Timer0
               Disable Adc
               Aux_l = 0
               While Aux_l < Pumem
                  U1 = Aux_l
                  Call Rd_e2
                  Printbin M
                  Incr Aux_l
               Wend
               K = Rtc_m_st + 6
               M = &H03
               Call Wr_rtc
               Call Ini_var
               Enable Adc
               Start Timer0
               If Reg_flg = 1 Then Start Timer1
            Case E_min:                                     'Transmite datos del equipo  -->  "ESC e" y devuelve los datos del equipo
               Print Equipo
               Print Modulo
               Print "Versi" ; Chr(162) ; "n:  " ; Version(2)
               Print Fecha
               Print Autor
               Print Usuario
            Case F_min:                                     'Ver lista de comandos --> "ESC f"
               Call Prt_help_com
            Case H_min:                                     'Ver reloj  -->  "ESC h"
               Call Get_time
               Call Prt_time
            Case M_min:                                     'Ver memoria utilizada y restante: --> "ESC m"
               Call Mem_restante
            Case T_min:                                     'Señal de Trigger
               If Bst_flg = 1 Then
                  Cont_tmp = 0
                  Timer1 = T1_start2
                  Start Timer1
               End If
            Case Else:
               Error = "N"
         End Select
         If Error = "N" Then Printbin Naknn
         If Error = "A" Then Printbin Acknn
         Set Testigo1
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
      Reset Watchdog
   Loop
   Return
#endif

'---------------------------------------------------------------------

End