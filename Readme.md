Script um zwei Lüfter per gpio 18 und 12 zu steuern.
Benutzt wird wiringpi 

Es wird eine Soll Temperatur eingestellt, bei der der Raspberry fast keinen Luftstrom benötigt.
Bei unterschreiten dieser Temperatur werden die Lüfter immer weiter heruntergefahren, bis diese entweder aus oder unhörbar leise sind.
Bei überschreiten der Temperatur werden die Lüfter aufgedreht Bis zum Maximun.
Sollte die Fail_Temp erreicht werden, wird der Raspberry abgeschaltet.


Anweisung:
Es wird eine NPN Transistor schaltung benötigt.
Ein Kondensator mit mehr als 100 uF sollte parallel zum Lüfter geschaltet werden.
Widerstand an der Basis des Transistors: 

Bsp.:
- Der Lüfter/LED Stripe benötigt 150mA
- Am gpio pin kommen 3.3V raus
- Verwendet wird ein BC337-40 NPN Transistor: hfe=250 V=0,7V

Ib= Ic / hfe = 0,150A / 250 = 0,0006 A
Ib = 0,0006A * 3 = 0,0018A
Ub = Vcc - Vt = 3,3V - 0,7V = 2,6V
Rb = Ub / Ib = 2,6V / 0,0018A = 1440 Ohm = 1.4 kOhm


Man könnte zwar den Kondensator berechnen, dies ist aber unnötig.
Ein Kondensator mit über 100 uF reicht aus um die Einschaltflanke abzuschwächen. (220uF, 470uF...)

Unbedingt ausprobieren bei welcher Geachwindigkeit der Lüfter anspringt oder die Leds leuchten.
Bsp.: Beim Befehl gpio pwm 18 285 dreht der lufter gerade so eben, und bei gpio pwm 18 450 wird der lufter nicht mehr achneller.
Diese beiden Minimum und Maximum werte in das Sxript eintragen.
