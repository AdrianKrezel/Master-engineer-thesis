/*-------------------------------------------------------------------------------------------------------
--------------------------------- DODANIE BIBLIOTEK ----------------------------------------------------- 
---------------------------------------------------------------------------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "main.h"

#include "tm_stm32_gpio.h"
#include "tm_stm32_rcc.h"
#include "tm_stm32_delay.h"
#include "tm_stm32_ds18b20.h"
#include "tm_stm32_onewire.h"


#ifdef _RTE_
#include "RTE_Components.h"             // Component selection
#endif
#ifdef RTE_CMSIS_RTOS                   // when RTE component CMSIS RTOS is used
#include "cmsis_os.h"                   // CMSIS RTOS header file
#endif

/*-------------------------------------------------------------------------------------------------------
------------------------------- DEKLARACJA ZMIENNYCH ---------------------------------------------------- 
---------------------------------------------------------------------------------------------------------*/
//Adresy sprzetowe termometrów
uint8_t termometr1[8]  = {0x28,0xFF,0xEA,0x26,0x34,0x16,0x04,0x31}; //t1
uint8_t termometr2[8]  = {0x28,0xFF,0x95,0xD9,0x04,0x16,0x03,0x85}; //t2
uint8_t termometr3[8]  = {0x28,0xFF,0x9A,0x1F,0x05,0x16,0x03,0x71}; //t3 
uint8_t termometr4[8]  = {0x28,0xFF,0x8F,0xDA,0x04,0x16,0x03,0xCC}; //t4
uint8_t termometr5[8]  = {0x28,0xFF,0x84,0xF1,0x04,0x16,0x03,0x58}; //t5   
uint8_t termometr6[8]  = {0x28,0xB0,0x5C,0x7A,0x08,0x00,0x00,0x3B}; //t6
uint8_t termometr7[8]  = {0x28,0xFF,0xE4,0x41,0x84,0x16,0x03,0xBA}; //t7
uint8_t termometr8[8]  = {0x28,0x09,0x2E,0x7A,0x08,0x00,0x00,0x44}; //t8
uint8_t termometr9[8]  = {0x28,0x1E,0x89,0x7A,0x08,0x00,0x00,0xF8}; //t9
uint8_t termometr10[8] = {0x28,0x8E,0x72,0x7A,0x08,0x00,0x00,0x9F}; //t10

//Wartosci temperatur
//	Temperatura powietrza w pomieszczeniach
float temp1 = 0.0f;
float temp2 = 0.0f;
float temp3 = 0.0f;
float temp4 = 0.0f;
float temp5 = 0.0f;
//  Temperatura grzejnikow
float temp6 = 0.0f;
float temp7 = 0.0f;
float temp8 = 0.0f;
float temp9 = 0.0f;
float temp10 = 0.0f;

//OneWire
uint8_t address[8]={0};
uint8_t devices = 0;
uint8_t count = 0;

//Init OneWire
GPIO_InitTypeDef 	GPIO_InitStruct;
TM_OneWire_t OneWire1;

//Init Timery
TIM_HandleTypeDef htim2;
TIM_HandleTypeDef htim3;
TIM_HandleTypeDef htim8;
TIM_HandleTypeDef htim11;
TIM_HandleTypeDef htim12;
TIM_HandleTypeDef htim4;

//Init UART
UART_HandleTypeDef huart1;

//Konfiguracja ukladow wewnetrznych mikrokontrolera
static void SystemClock_Config(void);
static void Error_Handler(void);
static void MX_GPIO_Init(void);
static void MPU_Config(void);
static void CPU_CACHE_Enable(void);
static void MX_TIM2_Init(void);
static void MX_TIM11_Init(void);
static void MX_TIM12_Init(void);
static void MX_TIM3_Init(void);
static void MX_TIM8_Init(void);
static void MX_TIM4_Init(void);
static void MX_USART1_UART_Init(void);

extern void Init_Timers (void);

/* Private functions ---------------------------------------------------------*/
#define grzejnik1  1
#define grzejnik2  2
#define grzejnik3  3
#define grzejnik4  4
#define grzejnik5  5 
#define wentylator 6

//Wartosci obliczonych sterowan dla urzadzen wykonawczych (wejscie obiektu regulacji)
int PWM1 = 0;
int PWM2 = 0;
int PWM3 = 0;
int PWM4 = 0;
int PWM5 = 0;
int PWM6 = 0;

//Bufory transmisji danych
char aRxBuffer[80] = " ";
char aTxBuffer[123] = " ";

//RTOS
int32_t czas_pocz = 0;
int32_t czas_konc = 0;

//Konwersja obliczonego przez PC sterowania z formatu char na int
int PWM_integer(char* bufor, char* PWMstr){ 			  //funkcja zwraca wartoœæ PWM w formacie int (liczby po znaku '=')
    //--------------------------------------------
    //Output: wartosc PWM w formacie float
    //Input:  wskaznik na bufor, wskaznik na PWM
    //--------------------------------------------

    char ch = ' ';                  		  			  //sprawdzany znak
    int i=0;                        		 			  //licznik do iterowania kolejnych znakow stringa
    char tablicaString[10] = " ";   		 			  //tablica do której zapisywany jest string cyfr (!zaklada siê ze wartoœc znajdzie siê w pierwszych 10 znakach nowego bufora)
    int tabi = 0;                   		 			  //indeks tablicy do ktorego zapisywana jest cyfra
    int flag = 0;                   					  //odblokowanie zapisu do tablicy po znaku '=' oraz zablokowanie po znaku ';'
    int wartosc = 0;

    char *string2 = strstr(bufor,PWMstr);    			  //utworzenie nowego bufora z danymi (na poczatku interesujacy nas PWM)

    for(i=0; i<=250; i++){          		 			  //sprawdzanie kolejnych znaków
        ch = string2[i];
        if((ch>='0' && ch<='9') || ch=='-' || ch=='.'){   //liczba lub minus lub kropka
            if (flag==1){					 			  //zapis po wykryciu znaku '='
                tablicaString[tabi]=ch; 				  //zapisanie cyfry do tablicy
                tabi++;
            }
        }
        else if ((ch >= 'a' && ch <='z') || (ch >= 'A' && ch <='Z')){ //litera
        }
        else if (ch=='='){  							 //rowna sie
            flag = 1; 									 //odblokowanie zapisu do tablicy
        }
        else if (ch==';'){ 								 //srednik
            flag = 0; 								 	 //blokada zapisu do tablicy
            break; 										 //przerwanie zapisywania
        }
    }													 //na tym etapie mam w tablicy liczbe char do przetworzenia na int

    wartosc = atoi(tablicaString);
}

//Metoda wystawiajaca obliczone wartosci sterowan na urzadzenia wykonawcze
void setPWM(int wyjscie, int value){
	switch(wyjscie){
		case grzejnik1:
			TIM3->CCR1 = PWM_integer(aRxBuffer, "PWM1");
			break;
		case grzejnik2:
			TIM2->CCR1 = PWM_integer(aRxBuffer, "PWM2");
			break;
		case grzejnik3:
			TIM12->CCR2 = PWM_integer(aRxBuffer, "PWM3");
			break;
		case grzejnik4:
			TIM12->CCR1 = PWM_integer(aRxBuffer, "PWM4");
			break;
		case grzejnik5:
			TIM11->CCR1 = PWM_integer(aRxBuffer, "PWM5");
			break;
		case wentylator:
		TIM4->CCR3 = PWM_integer(aRxBuffer, "PWM6");
		break;
		default:
			break;
	}
}

int lpp = 0;
int i;
char zabezp=' ';
float temp_kryt = 115.0f; //temp krytyczna - temp. zadzialania zabezpieczenia powyzej ktorej nastapi automatyczne programowe
						  //	wylaczenie zasilania grzejnikow w przypadku awarii nadrzednego ukladu sterowania

/*-------------------------------------------------------------------------------------------------------
---------------------------------- FUNKCJA GLOWNA ------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------*/
int main(void){

	//Uruchomienie CACHE
	CPU_CACHE_Enable();

	#ifdef RTE_CMSIS_RTOS                   // when using CMSIS RTOS
	  osKernelInitialize();                 // initialize CMSIS-RTOS
	#endif

	//Inicjalizacja biblioteki HAL dla mikrokontrolera STM32F7
	HAL_Init();

	//Konfiguracja zegara mikrokontrolera
	SystemClock_Config();

	//Start Kernela dla RTOS
	#ifdef RTE_CMSIS_RTOS                  
	  osKernelStart();                     
	#endif

	//Inicjalizacja
	LED_Initialize(); 		//LED
	MX_GPIO_Init();			//GPIO
	MX_USART1_UART_Init();	//UART
	
	TM_DELAY_Init();
	TM_GPIO_Init(GPIOA, GPIO_Pin_0, TM_GPIO_Mode_OUT, TM_GPIO_OType_OD, TM_GPIO_PuPd_NOPULL, TM_GPIO_Speed_Medium); //GPIO: ustawienia trybu
	TM_OneWire_Init(&OneWire1,GPIOA,GPIO_Pin_0); //podmapowanie pinu dla OneWire (do odczytu pomiarow temperatury)
	devices = TM_OneWire_First(&OneWire1);

	//Inicjalizacja timerow
	MX_TIM2_Init();
	MX_TIM11_Init();
	MX_TIM12_Init();
	MX_TIM3_Init();
	MX_TIM8_Init();
	MX_TIM4_Init();
 
	//Uruchomienie timerow
	HAL_TIM_PWM_Start(&htim2, TIM_CHANNEL_1);
	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
	HAL_TIM_PWM_Start(&htim8, TIM_CHANNEL_4);
	HAL_TIM_PWM_Start(&htim11,TIM_CHANNEL_1);
	HAL_TIM_PWM_Start(&htim12,TIM_CHANNEL_1);
	HAL_TIM_PWM_Start(&htim12,TIM_CHANNEL_2);
	HAL_TIM_PWM_Start(&htim4,TIM_CHANNEL_3);
	
	//Skanowanie adresów czujnikow temperatury DS18B20 podlaczonych do magistrali OneWire
	while (devices) { 
		++count;
		TM_OneWire_GetFullROM(&OneWire1, address);
		TM_DS18B20_SetResolution(&OneWire1,  address, TM_DS18B20_Resolution_12bits); //ustawienie rozdzielczosci pomiaru na 12 bitow
		devices = TM_OneWire_Next(&OneWire1);
	}
	
	//Petla glowna programu
	while(1){
		czas_pocz = HAL_GetTick();		//przechwycenie czasu startu wykonywania petli 	
		HAL_Delay(9370); //Tp=10		//ustawienia okresu probkowania temperatur
		//HAL_Delay(19570);	 //Tp=20
		//zadanie pomiaru temperatury
		TM_DS18B20_StartAll(&OneWire1);		
		while(! TM_DS18B20_AllDone(&OneWire1) );
	
		//Odczyt temperatur
		lpp = 0;
		lpp += TM_DS18B20_Read(&OneWire1, termometr1, &temp1);
		lpp += TM_DS18B20_Read(&OneWire1, termometr2, &temp2);
		lpp += TM_DS18B20_Read(&OneWire1, termometr3, &temp3);
		lpp += TM_DS18B20_Read(&OneWire1, termometr4, &temp4);
		lpp += TM_DS18B20_Read(&OneWire1, termometr5, &temp5);
		lpp += TM_DS18B20_Read(&OneWire1, termometr6, &temp6);
		lpp += TM_DS18B20_Read(&OneWire1, termometr7, &temp7);
		lpp += TM_DS18B20_Read(&OneWire1, termometr8, &temp8);
		lpp += TM_DS18B20_Read(&OneWire1, termometr9, &temp9);
		lpp += TM_DS18B20_Read(&OneWire1, termometr10, &temp10);
		
		//Wyslanie i odbior danych
		sprintf(aTxBuffer,"t1=%8.4f;t2=%8.4f;t3=%8.4f;t4=%8.4f;t5=%8.4f;t6=%8.4f;t7=%8.4f;t8=%8.4f;t9=%8.4f;t10=%8.4f;\n\r",temp1,temp2,temp3,temp4,temp5,temp6,temp7,temp8,temp9,temp10);
		HAL_UART_Transmit_IT(&huart1,(uint8_t*)aTxBuffer,sizeof(aTxBuffer)); 
		HAL_UART_Receive_IT(&huart1,(uint8_t*)aRxBuffer,sizeof(aRxBuffer));
		
		//Zabezpiecznie krytyczne (115*C)
		//	Po przekroczeniu temp. krytycznej w ewentualnej awarii wyzerowanie sterowan 
		//	grzejnikow w celu zabezpieczenia przed mechanicznymi uszkodzeniami makiety domu wykonanej z plexi
		if (temp6>=temp_kryt || temp7>=temp_kryt || temp8>=temp_kryt || temp9>=temp_kryt ||temp10>=temp_kryt)	break;
		
		//Ustawienie wartosci sygnalow sterujacych
		PWM1 = PWM_integer(aRxBuffer, "PWM1");	//PWM1	
		PWM2 = PWM_integer(aRxBuffer, "PWM2");	//PWM2
		PWM3 = PWM_integer(aRxBuffer, "PWM3");	//PWM3
		PWM4 = PWM_integer(aRxBuffer, "PWM4");	//PWM4
		PWM5 = PWM_integer(aRxBuffer, "PWM5");	//PWM5
		PWM6 = PWM_integer(aRxBuffer, "PWM6");	//PWM6

		setPWM(grzejnik1,  PWM1);  				//PWM1
		setPWM(grzejnik2,  PWM2);	 			//PWM2
		setPWM(grzejnik3,  PWM3);	 			//PWM3
		setPWM(grzejnik4,  PWM4);	 			//PWM4
		setPWM(grzejnik5,  PWM5);	 			//PWM5
		setPWM(wentylator, PWM6);  				//PWM6
		
 		while((HAL_GetTick()-czas_pocz)<1000);	//RTOS: gwarant wykonania kazdej iteracji petli w jednakowych odstepach czasu
	}
	
	//ZABEZPIECZENIE KRYTYCZNE DRUGIEGO STOPNIA (z poziomu mikrokontrolera)
	while(1){ 			//zabezpieczenie 115*C - reakcja => wylacz sterowanie i przejdz w tryb awaryjny
		zabezp='E';		//Zmiana stanu zmiennej syglalizcujacej awarie ukladu sterowania (podglad zmiennej w trybie debugowania)
		LED_On(0);		//Miganie diody sygnalizujacej awarie ukladu sterowania

		TM_DS18B20_StartAll(&OneWire1);		
		while(! TM_DS18B20_AllDone(&OneWire1) );
		TM_DS18B20_Read(&OneWire1, termometr1, &temp1);
		TM_DS18B20_Read(&OneWire1, termometr2, &temp2);
		TM_DS18B20_Read(&OneWire1, termometr3, &temp3);
		TM_DS18B20_Read(&OneWire1, termometr4, &temp4);
		TM_DS18B20_Read(&OneWire1, termometr5, &temp5);
		TM_DS18B20_Read(&OneWire1, termometr6, &temp6);
		TM_DS18B20_Read(&OneWire1, termometr7, &temp7);
		TM_DS18B20_Read(&OneWire1, termometr8, &temp8);
		TM_DS18B20_Read(&OneWire1, termometr9, &temp9);
		TM_DS18B20_Read(&OneWire1, termometr10, &temp10);
		for (i=0; i<sizeof(aRxBuffer); i++){
			aRxBuffer[i] = ' ';
		}	
		//Awaryjne wyzerowanie sterowan
		PWM1=0; setPWM(grzejnik1,  PWM1);  		//PWM1
		PWM2=0; setPWM(grzejnik2,  PWM2);	 	//PWM2
		PWM3=0; setPWM(grzejnik3,  PWM3);	 	//PWM3
		PWM4=0; setPWM(grzejnik4,  PWM4);	 	//PWM4
		PWM5=0; setPWM(grzejnik5,  PWM5);	 	//PWM5
		PWM6=200; setPWM(wentylator, PWM6);  	//PWM6
		LED_Off(0);		//Miganie diody sygnalizujacej awarie ukladu sterowania
		HAL_Delay(500);	//Miganie diody sygnalizujacej awarie ukladu sterowania
	}
}


/*-------------------------------------------------------------------------------------------------------
---------------------------------- KONFIGURACJA uC ------------------------------------------------------ 
---------------------------------------------------------------------------------------------------------*/

// Konfiguracja zegara uC ---------------------------------------------------------------------------------
void SystemClock_Config(void)
{

	RCC_OscInitTypeDef RCC_OscInitStruct;
	RCC_ClkInitTypeDef RCC_ClkInitStruct;
	RCC_PeriphCLKInitTypeDef PeriphClkInitStruct;

	__HAL_RCC_PWR_CLK_ENABLE();

	__HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);


	RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
	RCC_OscInitStruct.HSIState = RCC_HSI_ON;
	RCC_OscInitStruct.HSICalibrationValue = 16;
	RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
	RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
	RCC_OscInitStruct.PLL.PLLM = 8;
	RCC_OscInitStruct.PLL.PLLN = 216;
	RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
	RCC_OscInitStruct.PLL.PLLQ = 2;
	if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK){
		Error_Handler();
	}
	if (HAL_PWREx_EnableOverDrive() != HAL_OK){
		Error_Handler();
	}

	RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
							  |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
	RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
	RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
	RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV16;
	RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV16;
	if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_7) != HAL_OK){
		Error_Handler();
	}

	PeriphClkInitStruct.PeriphClockSelection = RCC_PERIPHCLK_USART1;
	PeriphClkInitStruct.Usart1ClockSelection = RCC_USART1CLKSOURCE_PCLK2;
	if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInitStruct) != HAL_OK){
		Error_Handler();
	}

	HAL_SYSTICK_Config(HAL_RCC_GetHCLKFreq()/1000);

	HAL_SYSTICK_CLKSourceConfig(SYSTICK_CLKSOURCE_HCLK);

	/* SysTick_IRQn interrupt configuration */
	HAL_NVIC_SetPriority(SysTick_IRQn, 0, 0);
}

// Error handler ------------------------------------------------------------------------------------------
static void Error_Handler(void){
	/* User may add here some code to deal with this error */
	while(1){}
}

// Konfiguracja MPU ---------------------------------------------------------------------------------------
static void MPU_Config(void){
	MPU_Region_InitTypeDef MPU_InitStruct;

	/* Disable the MPU */
	HAL_MPU_Disable();

	/* Configure the MPU attributes as WT for SRAM */
	MPU_InitStruct.Enable = MPU_REGION_ENABLE;
	MPU_InitStruct.BaseAddress = 0x20010000;
	MPU_InitStruct.Size = MPU_REGION_SIZE_256KB;
	MPU_InitStruct.AccessPermission = MPU_REGION_FULL_ACCESS;
	MPU_InitStruct.IsBufferable = MPU_ACCESS_NOT_BUFFERABLE;
	MPU_InitStruct.IsCacheable = MPU_ACCESS_CACHEABLE;
	MPU_InitStruct.IsShareable = MPU_ACCESS_SHAREABLE;
	MPU_InitStruct.Number = MPU_REGION_NUMBER0;
	MPU_InitStruct.TypeExtField = MPU_TEX_LEVEL0;
	MPU_InitStruct.SubRegionDisable = 0x00;
	MPU_InitStruct.DisableExec = MPU_INSTRUCTION_ACCESS_ENABLE;

	HAL_MPU_ConfigRegion(&MPU_InitStruct);

	/* Enable the MPU */
	HAL_MPU_Enable(MPU_PRIVILEGED_DEFAULT);
}

/**
  * @brief  CPU L1-Cache enable.
  * @param  None
  * @retval None
  */
static void CPU_CACHE_Enable(void){
	/* Enable I-Cache */
	SCB_EnableICache();

	/* Enable D-Cache */
	SCB_EnableDCache();
}

#ifdef  USE_FULL_ASSERT

/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t* file, uint32_t line){ 
	/* User can add his own implementation to report the file name and line number,
	 ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */

	/* Infinite loop */
	while (1){}
}
#endif

// Konfiguracja Timera2 ----------------------------------------------------------------------------------
static void MX_TIM2_Init(void)
{

	TIM_MasterConfigTypeDef sMasterConfig;
	TIM_OC_InitTypeDef sConfigOC;

	htim2.Instance = TIM2;
	htim2.Init.Prescaler = 64;
	htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim2.Init.Period = 200;
	htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	if (HAL_TIM_PWM_Init(&htim2) != HAL_OK){
		Error_Handler();
	}

	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK){
		Error_Handler();
	}

	sConfigOC.OCMode = TIM_OCMODE_PWM1;
	sConfigOC.Pulse = 0;
	sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
	sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
	if (HAL_TIM_PWM_ConfigChannel(&htim2, &sConfigOC, TIM_CHANNEL_1) != HAL_OK){
		Error_Handler();
	}

	HAL_TIM_MspPostInit(&htim2);

}

// Konfiguracja Timera3 -----------------------------------------------------------------------------------
static void MX_TIM3_Init(void){

	TIM_MasterConfigTypeDef sMasterConfig;
	TIM_OC_InitTypeDef sConfigOC;

	htim3.Instance = TIM3;
	htim3.Init.Prescaler = 64;
	htim3.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim3.Init.Period = 200;
	htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	if (HAL_TIM_PWM_Init(&htim3) != HAL_OK){
		Error_Handler();
	}

	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	if (HAL_TIMEx_MasterConfigSynchronization(&htim3, &sMasterConfig) != HAL_OK){
		Error_Handler();
	}

	sConfigOC.OCMode = TIM_OCMODE_PWM1;
	sConfigOC.Pulse = 0;
	sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
	sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
	if (HAL_TIM_PWM_ConfigChannel(&htim3, &sConfigOC, TIM_CHANNEL_1) != HAL_OK){
		Error_Handler();
	}

	HAL_TIM_MspPostInit(&htim3);

}

// Konfiguracja Timera4 -----------------------------------------------------------------------------------
static void MX_TIM4_Init(void)
{

	TIM_MasterConfigTypeDef sMasterConfig;
	TIM_OC_InitTypeDef sConfigOC;

	htim4.Instance = TIM4;
	htim4.Init.Prescaler = 64;
	htim4.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim4.Init.Period = 200;
	htim4.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	if (HAL_TIM_PWM_Init(&htim4) != HAL_OK){
		Error_Handler();
	}

	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	if (HAL_TIMEx_MasterConfigSynchronization(&htim4, &sMasterConfig) != HAL_OK){
		Error_Handler();
	}

	sConfigOC.OCMode = TIM_OCMODE_PWM1;
	sConfigOC.Pulse = 0;
	sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
	sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
	if (HAL_TIM_PWM_ConfigChannel(&htim4, &sConfigOC, TIM_CHANNEL_3) != HAL_OK){
		Error_Handler();
	}

	HAL_TIM_MspPostInit(&htim4);

}
// Konfiguracja Timera8 -----------------------------------------------------------------------------------
static void MX_TIM8_Init(void){

	TIM_MasterConfigTypeDef sMasterConfig;
	TIM_BreakDeadTimeConfigTypeDef sBreakDeadTimeConfig;
	TIM_OC_InitTypeDef sConfigOC;

	htim8.Instance = TIM8;
	htim8.Init.Prescaler = 64;
	htim8.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim8.Init.Period = 200;
	htim8.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	htim8.Init.RepetitionCounter = 0;
	if (HAL_TIM_PWM_Init(&htim8) != HAL_OK){
		Error_Handler();
	}

	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterOutputTrigger2 = TIM_TRGO2_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	if (HAL_TIMEx_MasterConfigSynchronization(&htim8, &sMasterConfig) != HAL_OK){
		Error_Handler();
	}

	sBreakDeadTimeConfig.OffStateIDLEMode = TIM_OSSI_DISABLE;
	sBreakDeadTimeConfig.LockLevel = TIM_LOCKLEVEL_OFF;
	sBreakDeadTimeConfig.DeadTime = 0;
	sBreakDeadTimeConfig.BreakState = TIM_BREAK_DISABLE;
	sBreakDeadTimeConfig.BreakPolarity = TIM_BREAKPOLARITY_HIGH;
	sBreakDeadTimeConfig.BreakFilter = 0;
	sBreakDeadTimeConfig.Break2State = TIM_BREAK2_DISABLE;
	sBreakDeadTimeConfig.Break2Polarity = TIM_BREAK2POLARITY_HIGH;
	sBreakDeadTimeConfig.Break2Filter = 0;
	sBreakDeadTimeConfig.AutomaticOutput = TIM_AUTOMATICOUTPUT_DISABLE;
	if (HAL_TIMEx_ConfigBreakDeadTime(&htim8, &sBreakDeadTimeConfig) != HAL_OK){
		Error_Handler();
	}

	sConfigOC.OCMode = TIM_OCMODE_PWM1;
	sConfigOC.Pulse = 0;
	sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
	sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
	sConfigOC.OCIdleState = TIM_OCIDLESTATE_RESET;
	sConfigOC.OCNIdleState = TIM_OCNIDLESTATE_RESET;
	if (HAL_TIM_PWM_ConfigChannel(&htim8, &sConfigOC, TIM_CHANNEL_4) != HAL_OK){
		Error_Handler();
	}

	HAL_TIM_MspPostInit(&htim8);

}

// Konfiguracja Timera11 ----------------------------------------------------------------------------------
static void MX_TIM11_Init(void){

	TIM_OC_InitTypeDef sConfigOC;

	htim11.Instance = TIM11;
	htim11.Init.Prescaler = 64;
	htim11.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim11.Init.Period = 200;
	htim11.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	if (HAL_TIM_Base_Init(&htim11) != HAL_OK){
		Error_Handler();
	}

	if (HAL_TIM_PWM_Init(&htim11) != HAL_OK){
		Error_Handler();
	}

	sConfigOC.OCMode = TIM_OCMODE_PWM1;
	sConfigOC.Pulse = 0;
	sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
	sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
	if (HAL_TIM_PWM_ConfigChannel(&htim11, &sConfigOC, TIM_CHANNEL_1) != HAL_OK){
		Error_Handler();
	}

	HAL_TIM_MspPostInit(&htim11);

}

// Konfiguracja Timera12 ----------------------------------------------------------------------------------
static void MX_TIM12_Init(void){

	TIM_OC_InitTypeDef sConfigOC;

	htim12.Instance = TIM12;
	htim12.Init.Prescaler = 64;
	htim12.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim12.Init.Period = 200;
	htim12.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	if (HAL_TIM_PWM_Init(&htim12) != HAL_OK){
		Error_Handler();
	}

	sConfigOC.OCMode = TIM_OCMODE_PWM1;
	sConfigOC.Pulse = 0;
	sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
	sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
	if (HAL_TIM_PWM_ConfigChannel(&htim12, &sConfigOC, TIM_CHANNEL_1) != HAL_OK){
		Error_Handler();
	}

	if (HAL_TIM_PWM_ConfigChannel(&htim12, &sConfigOC, TIM_CHANNEL_2) != HAL_OK){
		Error_Handler();
	}

	HAL_TIM_MspPostInit(&htim12);

}

// Inicjalizacja GPIO -------------------------------------------------------------------------------------
static void MX_GPIO_Init(void){

	/* GPIO Ports Clock Enable */
	__HAL_RCC_GPIOB_CLK_ENABLE();
	__HAL_RCC_GPIOA_CLK_ENABLE();
	__HAL_RCC_GPIOI_CLK_ENABLE();
	__HAL_RCC_GPIOH_CLK_ENABLE();
	__HAL_RCC_GPIOC_CLK_ENABLE();
}

// Inicjalizacja UART -------------------------------------------------------------------------------------
static void MX_USART1_UART_Init(void)
{
	
	huart1.Instance = USART1;
	huart1.Init.BaudRate = 115200;
	huart1.Init.WordLength = UART_WORDLENGTH_8B;
	huart1.Init.StopBits = UART_STOPBITS_1;
	huart1.Init.Parity = UART_PARITY_NONE;
	huart1.Init.Mode = UART_MODE_TX_RX;
	huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart1.Init.OverSampling = UART_OVERSAMPLING_16;
	huart1.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
	huart1.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
	if (HAL_UART_Init(&huart1) != HAL_OK){
		Error_Handler();
	}

}


/*-------------------------------------------------------------------------------------------------------
---------------------------------- FUNKCJE PRYWATNE ----------------------------------------------------- 
---------------------------------------------------------------------------------------------------------*/


