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
'22/06/2014 - Ver: 2.5
'Se cambia TIMER1 para burst (Se lo hace contar mas)
'
'23/06/2014 - Ver: 2.6
'Se cambia TIMER1 para burst seteádolo al principio
'y poniendo un flag de disparo del TIMER1 porque ????????????????
'
'25/06/2014 - Ver: 2.7
'Se restructuraron los timers: TIMER0 para Burst, TIMER1 para Registro
'Se cambio conversión ADC para que se autoreinicie en la interrupción.
'
'26/06/2014 - Ver: 2.8
'Se pasaron las variables a conservar sin energía de la E2 del uC a
'la memoria RAM del Reloj DS1307
'
'27/06/2014 - Ver: 2.9
'Se emprolija archivo sacando las instrucciones comentadas
'
'28/06/2014 - Ver: 2.10
'Se cambia buzzer por potenciómetro para entrada canal ?
'Se pone comando para habilitar y deshabilitar el potenciómetro (Default --> Habilitado
'Se agrega comando para resetear el equipo por soft --> "ESC Z"
'
'05/07/2014 - Ver: 2.11
'Se agrega comandp para medir tiempos entre eventos
'
'09/07/2014 - Ver: 2.12
'Se cambia cristal de 12Mhz a 16Mhz
'
'12/07/2014 - Ver: 2.13
'Se cambia pregunta para "graba_ini" en Sub ini_var
'Solo graba inicialización y se chequean parámetros si reg_flg=1
'
'13/07/2014 - Ver: 2.14
'Se agrega Timeout para comunicación serial
'Se saca comando "ESC D" por estar definido por el Hardware
'Se verifica ingresos de datos en los Input y los Waitkey.
'
'22/08/2014 - Ver: 2.15
'Se cambia lógica de "Int_ADC" para que coincidan las secuencia de los canales
'Se agrega comando "ESC U" para transmisión contínua un canal específico con
'intervalo a elección del usuario.
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
'$regfile = "m2560def.dat"
$crystal = 16000000

$hwstack = 48
$swstack = 16
$framesize = 32
$version 2 , 15 , 8
$timeout = 8000000

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
Const Equipo = "Proyecto: AD"
Const Modulo = "Equipo:   AQC01"
Const Fecha = "Fecha:    22/08/2014"
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
Const T0_start1 = 56                                        'Ya que -->  256-200=56 (Cuenta 200 y desborda el T0)
Const T1_start1 = 3036                                      'Ya que -->  65536-62500=3036 (Cuenta 62500 y desborda el T1)
Const T3_start1 = 0
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
Dim Tx1c_flg As Bit
Dim Trcont_flg As Bit
Dim Mt_flg As Bit
'------
Dim Error As Byte                                           ' "0"=no importa || "A"=Ack  ||  "N"=Nak
Dim Canal As Byte
Dim Bwd As Byte
Dim Aux_b As Byte
Dim Com_in As Byte
Dim Cant_canal As Byte
Dim Can_esp As Byte
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
Dim Cfg_mt As Byte
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
Dim Cont_tm3 As Word
'------
Dim U1 As Long
Dim Pumem As Long
Dim Aux_l As Long
Dim Delta_t As Long
'------
Dim Buffprt As String * 24

'--------------------------------------------------------------
'Declaración de variables internas en EEPROM
'--------------------------------------------------------------
'
'
'--------------------------------------------------------------
'Rutina que permite saber si se reseteó por W_dog
'--------------------------------------------------------------
Bwd = Peek(0)
If Bwd.wdrf = 1 Then
   Set Wd_flg
Else
   Reset Wd_flg
End If

'--------------------------------------------------------------
'Declaración de config´s
'--------------------------------------------------------------
   Config Scl = Portc.0                                     'Para 1284p
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
Config Timer0 = Timer , Prescale = 8                        'Interrumpe --> 16000000/8/200=10000 (Frec/prescaler/timer1) int/seg
Stop Timer0                                                 'O sea, cada 100 useg
Timer0 = T0_start1                                          'Ya que -->  256-200=56 (Cuenta 200 y desborda el T0)
'----
Config Timer1 = Timer , Prescale = 256                      'Interrumpe --> 16000000/256/62500=1 (Frec/prescaler/timer0) int/seg
Stop Timer1                                                 'O sea, cada 1 seg
Timer1 = T1_start1                                          'Ya que -->  65636-62500=3036 (Cuenta 62500 y desborda el T1)
'----
Config Timer3 = Timer , Prescale = 1                        'Interrumpe --> 16000000 int/seg
Stop Timer3
Timer3 = T3_start1                                          'Se inicializa en cero
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
   Config Pinc.4 = Input
   Config Pinc.5 = Input
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
   Potenc Alias Portc.2
   Mt_start Alias Pinc.4
   Mt_stop Alias Pinc.5
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
'   Config Pinc.4 = Input
'   Config Pinc.5 = Input
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
'   Potenc Alias Portc.2
'   Mt_start Alias Pinc.4
'   Mt_stop Alias Pinc.5

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

Mchip = 0
Wp = 1

If Wd_flg = 1 Then
   Print "WD"
   K = Rtc_m_st + 6
   M = &H0A                                                 'Código de WD
   Call Wr_rtc
End If

#if Proteus = 1
   Print Equipo
   Print Modulo
#endif

Reset Potenc

Set Testigo1
Reset Testigo2
For I = 1 To 8
   Toggle Testigo1
   Toggle Testigo2
   Waitms 125
Next I

Call Parada

#if Pfail = 1
   On Aci P_fail Nosave
   Enable Aci , Hi
#endif

On Timer0 Int_timer0
Enable Timer0

On Timer1 Int_timer1
Enable Timer1

On Timer3 Int_timer3
Enable Timer3

On Serial Rx_rs232
Enable Serial , Hi

On Int0 Int_int0

On Adc Int_adc
Enable Adc

Cant_dig = &HF0
Ddrb = Cant_dig
K = Rtc_m_st + 10
M = Cant_dig
Call Wr_rtc

Call Ini_var

Start Adc
Set Adcsra.6

Reset Cold_flg
Enable Interrupts

'--------------------------------------------------------------
'RUTINA PRINCIPAL
'--------------------------------------------------------------

Do

   If Mt_flg = 1 Then
      Reset Mt_flg

      Bitwait Mt_start , Reset
      Start Timer3

      If Cfg_mt = &H31 Then
         Bitwait Mt_start , Set
         Stop Timer3
      End If
      If Cfg_mt = &H32 Then
         Bitwait Mt_stop , Reset
         Stop Timer3
      End If

      Delta_t = Cont_tm3 * 65536
      Delta_t = Delta_t + Timer3
      Delta_t = Delta_t / 16
      Print Delta_t;
      Set Testigo2
   End If

   If Trcont_flg = 1 Then
      Reset Trcont_flg
      If Tx1c_flg = 1 Then
         Aux_w = Datos(can_esp)
         Printbin Aux_w
      Else
         Call Tx_rs232
      End If
   End If

   If Bst_listo = 1 Then
      Reset Bst_listo
      For Aux_i = 1 To Aux_punt
         Aux_w = Buff_bst(aux_i)
         Printbin Aux_w
      Next Aux_i
      Set Testigo2
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
   Stop Timer0
   Stop Timer3
   Reset Tx_flg
   Reset Trcont_flg
   Reset Esc_flg
   Reset Bst_flg
   Reset Tx1c_flg
   Reset Bst_listo
   Reset Mt_flg
   If Cold_flg = 0 Then
      Stop Timer1
      Reg_flg = 0
      K = Rtc_m_st + 7
      M = Reg_flg
      Call Wr_rtc
   End If
   Cont_tmp = 0
   Cont_tm3 = 0
   Set Testigo1
   Set Testigo2
End Sub

'---------------------------------------------------------------------
'Subrutina inicialización básica del equipo
Sub Ini_var
   Call Veri_ini
   Call Veri232_reloj
   If Reg_flg = 1 Then
      Call Graba_ini
      Start Timer1
   End If
End Sub

'---------------------------------------------------------------------
'Rutina que verifica reloj
Sub Veri232_reloj
   Local A As Byte

   K = Rtc_m_st
   Call Rd_rtc
   If M <> Acknn Then
      Call Parada
      Print "RNI"
   End If
End Sub

'---------------------------------------------------------------------
'Rutina que verifica la inicializacion
Sub Veri_ini
   K = Rtc_m_st + 10
   Call Rd_rtc
   Cant_dig = M
   Ddrb = Cant_dig

   K = Rtc_m_st + 5
   Call Rd_rtc
   Cant_canal = M
   If Cant_canal < 1 Or Cant_canal > Max_canal Then
      Cant_canal = Max_canal
      K = Rtc_m_st + 5
      M = Cant_canal
      Call Wr_rtc
   End If
   Canal = 0

   Reset Tx_flg
   Reset Trcont_flg
   Reset Esc_flg
   Reset Tx1c_flg
   K = Rtc_m_st + 7
   Call Rd_rtc
   Reg_flg = M

   K = Rtc_m_st + 8
   Call Rd_rtc
   T_reg = M
   Shift T_reg , Left , 8
   K = Rtc_m_st + 9
   Call Rd_rtc
   T_reg = T_reg Or M

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
      K = Rtc_m_st + 7
      M = Reg_flg
      Call Wr_rtc
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
   M = Cant_dig                                             'Seteo de canales digitales (Entradas y Salidas)
   Call Registro
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
   Stop Adc
   If Mem_full = 0 Then
      U1 = Pumem
      Call Wr_e2
      Incr Pumem
      Aux_l = Pumem
      If Pumem >= Mem_fin Then
         Reg_flg = 0
         K = Rtc_m_st + 7
         M = Reg_flg
         Call Wr_rtc
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
   Start Adc
   Set Adcsra.6
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
'      lcall wdog
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
   Print "ESC A <Cant_canal> --> Recibe cantidad de canales analógicos: <Cant_canal> de 1 a 8"
   Print
   Print "ESC B <T_reg> 0D 0A --> Recibe tiempo de registro en segundos: <T_reg> de 1 a 65535"
   Print
   Print "ESC C <byte> --> Mide tiempo entre dos señales en un mismo pin (PinC.4, falling y rising edge) o entre dos pines (PinC.4 falling  y PinC.5 falling)"
   Print "                 <byte> -->  <0x31> para Start y Stop en PinC.4 || <0x32> para Start en PinC.4 y Stop en PinC.5"
   Print "                 Devuelve el lapso de tiempo en useg (ASCII)"
   Print
'   Print "ESC D <byte> --> Recibe el seteo del sentido de los canales digitales (1=SAL, 0=ENT)"
'   Print
   Print "ESC H hhmmssDDMMAAAA --> Seteo de hora"
   Print
   Print "ESC I --> Borrado de memoria y Treg = 5seg || Tiempo de registro default: 60seg"
   Print
   Print "ESC O <trigger> <intervalo> 0D 0A --> Modo Burst"
   Print "      Trigger: 'R'=Int0/rising edge || 'F'=Int0/falling || 'P'=PC"
   Print "      Intervalo: (1 a 65535) x 100us"
   Print
   Print "ESC P --> Deshabilita todos los modos --> Solo escucha la RS232"
   Print
   Print "Esc R --> Habilita registro"
   Print
   Print "ESC S <byte> --> Setea las salidas de acuerdo a lo que recibe por RS232"
   Print
   Print "ESC T <Intervalo> --> Habilita transmisión de datos continuo con intervalo"
   Print "      Intervalo: (1 a 65535) x 100us"
   Print
   Print "ESC U <Canal> <Intervalo> --> Habilita transm. datos continuo de un canal con intervalo"
   Print "      Canal: 1 a 8  ; Intervalo: x100us  0D 0A"
   Print
   Print "ESC Z --> Reset del equipo"
   Print
   Print "ESC a --> Transmite datos de todos los canales analógicos steteados"
   Print
   Print "Esc b <Canal> --> Transmite el Canal Analógico Solicitado || <Canal> De 1 a 8 "
   Print
   Print "ESC c y devuelve <byte> --> Transmite estados de los canales digitales"
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
   Timer0 = T0_start1
   Toggle Testigo2
   Incr Cont_tmp
      If Cont_tmp = Intervalo Then
         Cont_tmp = 0
         If Bst_flg = 1 Then
            If Punt_wr < Buff_max_8 Then
               For I_it1 = 1 To Cant_canal
                  Buff_bst(punt_wr) = Datos(i_it1)
                  Incr Punt_wr
               Next I_it1
            Else
               Stop Timer0
               Aux_punt = Punt_wr - 1
               Punt_wr = 1
               Set Bst_listo
            End If
         Elseif Tx_flg = 1 Then
            Set Trcont_flg
         End If
      End If
Return

'---------------------------------------------------------------------
Int_timer1:
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
Return

'---------------------------------------------------------------------
Int_timer3:
   Incr Cont_tm3
Return

'---------------------------------------------------------------------
Int_adc:
   Aux_b = Admux
   Aux_b = Aux_b And &HF8
   Aux_b = Aux_b Or Canal
   Admux = Aux_b
   Aux_b = Adcl
   If Canal = 0 Then
      Datos(cant_canal) = Adch
      If Aux_b = &HFF Then Aux_b = &HFE
      Shift Datos(cant_canal) , Left , 8
      Datos(cant_canal) = Datos(cant_canal) Or Aux_b
   Else
      Datos(canal) = Adch
      If Aux_b = &HFF Then Aux_b = &HFE
      Shift Datos(canal) , Left , 8
      Datos(canal) = Datos(canal) Or Aux_b
   End If
   Incr Canal
   If Canal >= Cant_canal Then Canal = 0
   Set Adcsra.6
Return

'---------------------------------------------------------------------
Int_int0:
   If Bst_flg = 1 Then
      Stop Timer0
      Cont_tmp = 0
      Timer0 = T0_start1
      Start Timer0
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
            Error = "N"
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
'                  Error = "A"
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
'                  Error = "A"
            Case Nueve:                                     'Eco de un caracter cualquiera
               Com_in = Waitkey()
               Printbin Com_in
            Case A_may:                                     'Recibe cantidad de canales analógicos
               Com_in = Waitkey()                           'ESC A <num>  || <num> de 1 a 8
               If Com_in > 48 And Com_in < 57 Then
                  Cant_canal = Com_in - 48
                  K = Rtc_m_st + 5
                  M = Cant_canal
                  Call Wr_rtc
                  Canal = 0
                  K = Rtc_m_st + 6
                  M = &H09
                  Call Wr_rtc
                  Call Ini_var
'                  Error = "A"
               End If
            Case B_may:                                     'Recibe tiempo de registro en segundos
               Input Aux_w Noecho                           ' "ESC B <num> 0D 0A" || <num> de 1 a 65535
               If Aux_w > 0 And Aux_w <= 65535 Then
                  T_reg = Aux_w
                  K = Rtc_m_st + 8
                  M = High(t_reg)
                  Call Wr_rtc
                  K = Rtc_m_st + 9
                  M = Low(t_reg)
                  Call Wr_rtc
                  K = Rtc_m_st + 6
                  M = &H02
                  Call Wr_rtc
                  Call Ini_var
'                  Error = "A"
               End If
            Case C_may:                                     'Medición de tiempo:  "ESC C <byte>" --> <byte> 0 1 o 2
               Cfg_mt = Waitkey()                           '1 --> mismo pin  ||  2 --> dos pines
               If Cfg_mt >= 48 And Cfg_mt < 51 Then
                  Call Parada
                  Cont_tm3 = 0
                  Timer3 = T3_start1
                  Stop Timer3
                  Reset Testigo2
                  Set Mt_flg
'                  Error = "A"
               End If
'            Case D_may:                                     'Recibe el seteo del sentido de los canales digitales (1=SAL, 0=ENT) --> "ESC S" <byte>
'               Cant_dig = Waitkey()
'               Ddrb = Cant_dig
'               K = Rtc_m_st + 10
'               M = Cant_dig
'               Call Wr_rtc
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
               K = Rtc_m_st + 7
               M = Reg_flg
               Call Wr_rtc
               T_reg = 10                                   'Tiempo de registro default --> 10seg
               K = Rtc_m_st + 8
               M = High(t_reg)
               Call Wr_rtc
               K = Rtc_m_st + 9
               M = Low(t_reg)
               Call Wr_rtc
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
               Trigger = Waitkey()                          'Trigger: "R"=Int0/rising edge || "F"=Int0/falling || "P"=PC
               Input Intervalo Noecho                       'Intervalo: x100us  0D 0A
               If Trigger = "R" Or Trigger = "F" Or Trigger = "P" Then
                  If Intervalo > 0 And Intervalo <= 65535 Then
                     Call Parada
                     Set Bst_flg
                     Punt_wr = 1
                     Call Cfg_int0
'                     Error = "A"
                  End If
               End If
            Case P_may:                                     'Parada del equipo --> No hace nada, solo escuchar la RS232
               Call Parada
               'Error = "A"
            Case R_may:                                     'Habilita registro  -->  "Esc R"
               Call Parada
               Timer1 = T1_start1
               Reg_flg = 1
               K = Rtc_m_st + 7
               M = Reg_flg
               Call Wr_rtc
               K = Rtc_m_st + 6
               M = &H08
               Call Wr_rtc
               Call Ini_var
               Cont_tmp = 0
               Start Timer1
               'Error = "A"
            Case S_may:                                     'Setea las salidas de acuerdo a lo que recibe por RS232 --> "ESC S <byte>"
               Com_in = Waitkey()
               Portb = Ddrb And Com_in
               'Error = "A"
            Case T_may:                                     'Habilita transmisión de datos continuo con intervalo --> "ESC T"
               Input Intervalo Noecho                       'Intervalo: x100us  0D 0A
               If Intervalo > 0 And Intervalo <= 65535 Then
                  Call Parada
                  Cont_tmp = 0
                  Timer0 = T0_start1
                  Set Tx_flg
                  Start Timer0
'                  Error = "A"
               End If
            Case U_may :                                    'Habilita transm. datos continuo un canal con intervalo --> "ESC U Canal Intervalo"
               Can_esp = Waitkey()                          'Canal: 1 a 8  ; Intervalo: x100us  0D 0A
               Can_esp = Can_esp - 48
               Input Intervalo Noecho
               If Intervalo > 0 And Intervalo <= 65535 Then
                  Call Parada
                  Cont_tmp = 0
                  Timer0 = T0_start1
                  Set Tx_flg
                  Set Tx1c_flg
                  Start Timer0
'                  Error = "A"
               End If
            Case Y_may:                                     'Hab/Deshab el potenciómetro --> "ESC Y <byte>"
               Com_in = Waitkey()                           '<byte> = "H" o "D"
               If Com_in = "H" Then Reset Potenc
               If Com_in = "D" Then Set Potenc
            Case Z_may:                                     'Resetea el equipo --> "ESC Z"
               Disable Interrupts
               Config Watchdog = 16
'               Printbin Acknn
               Start Watchdog
               Do
               Loop
            Case A_min:                                     'Transmite datos de todos los canales analógicos steteados -->  "ESC a"
               Call Tx_rs232
            Case B_min :                                    'transmite El Canal Analógico Solicitado - - > "Esc b <byte>"
               Com_in = Waitkey()                           '|| < Byte > De 1 A 8 ""
               If Com_in > 48 And Com_in < 57 Then
                  I = Com_in - 48
                  Aux_w = Datos(i)
                  Printbin Aux_w
               End If
            Case C_min:                                     'Transmite estados de los canales digitales --> "ESC c" y devuelve <byte>
               Printbin Pinb
            Case D_min:                                     'Descarga de datos binaria --> "ESC d"
               Stop Timer1
               Stop Timer0
               Stop Adc
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
               Start Adc
               Set Adcsra.6
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
               If Bst_flg = 1 And Trigger = "P" Then
                  Cont_tmp = 0
                  Timer0 = T0_start1
                  Start Timer0
               End If
            Case Else:
               Error = "N"
         End Select
'         If Error = "N" Then Printbin Naknn
'         If Error = "A" Then Printbin Acknn
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