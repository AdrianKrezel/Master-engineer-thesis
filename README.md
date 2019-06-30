Synopsis:
1.	House model (5 rooms) made of plexi has STM32F7 microcontroller that is used for collecting air temerature measurements from every of the rooms and from every heater (that is installed in every of them). It is also used for sending the counted value of control signal to the input of heaters
2.	PC computer counts the control signal value for the heaters based on the measurements of air temperature in rooms. It also counts regulation quality indicators like standard deviation, quantity of energy osed for heating, etc.
3.	For STM32F7 and PC communication USB interface is used
4.	Implemended and tested algorithms: PID - classical regulator and DMC - predictive regulator with mathematical model of control process built-in. Mathematical models of executive devices (like heaters) influence on air temperature in rooms tested: Multiple Input Multiple Output and Single Input Single Output

Master thesis abstract: 
The thesis presents the process of designing the structure of the temperature control system for the object, which is a house model made in 1:25 scale. The project includes physical execution of the model from the mechanical part through the electronics project to the programming part, which consists of the implementation of control algorithms and control of electronic devices from the hardware side. The aim of the master thesis is to analyze the algorithms of classical regulation and multidimensional temperature in terms of energy savings necessary to heat the building. 
The first chapter includes an introduction to the subject of the diploma thesis. 
The second chapter contains a detailed house mock-up project, where the planned regulation structures will be verified. The first subsection contains information about the the mock-up principle of operation, the second contains the design of its mechanical construction. 
In the third subchapter, a project of electronics controlling the operation of the model is included, starting with the selection of sensors and actuators by selecting the control unit for the system operation. 
The fourth - the last subsection consists of the selection of environments and programming languages, that will be used to operate electronic devices on the mock-up side and to implement control algorithms on the PC computer side. The third chapter describes the classical and multivariate algorithms analyzed in this thesis, while the fourth chapter describes the method of creating a mathematical model of the mock-up, on which the control algorithms will be tested before they are verified on the physical model. 
The fifth chapter contains graphs with the results of the regulation algorithm tests. 
The sixth chapter describes the conclusions obtained from the research of control algorithms carried out both on the mathematical model and on the physical model of the building.

Technologies: STM32F7, C language, Matlab, PID algorithm, DMC algorithm, SISO model, MIMO model, UART
