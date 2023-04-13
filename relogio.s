/* 
Gustavo Silva Malvestiti
*/

# Observação: Não será necessária nenhuma mudança em Debugging Checks
# Observação: Todos os valores de leitura inválidos são modificados ou ignorados

# Variáveis na memória
.equ C1, 0x10000
.equ C2, 0x10004
.equ C3, 0x10008
.equ C4, 0x1000c
.equ F_TIMER, 0x10010
.equ F_CONTADOR, 0x10014
.equ F_ALARME, 0x10018
.equ PRINT, 0x1001c

# Endereço de início da pilha
.equ STACK, 0x1000

# Endereços dos dispositivos de I/O
.equ RLEDS, 0x10000000 # Endereço base dos LEDS vermelhos
.equ GLEDS, 0x10000010 # Endereço base dos LEDS verdes
.equ DISPLAYS, 0x10000020 # Endereço base dos displays HEX0 até HEX3
.equ DISPLAYS2, 0x10000030 # Endereço base dos displays HEX4 até HEX7
.equ SWITCHES, 0x10000040 # Endereço base dos switches
.equ BUTTONS, 0x10000050 # Endereço base dos botões
.equ UART, 0x10001000 # Endereço base do JTAG UART
.equ TIMER, 0x10002000 # Endereço base do temporizador

# RTI
.org 0x20
# Código da RTI
	# Store na pilha
	addi sp, sp, -12
	stw ra, 8(sp)
	stw r16, 4(sp)
	stw r17, 0(sp)
	# Descobrir quem gerou a interrupção
	rdctl et, ipending
	beq et, r0, SW_EXCEPTION
	# Interrupção de hardware
	addi ea, ea, -4
	# Testa se botões
	movi r17, 0b10 # Máscara do IRQ1 (Pushbutton)
	bne et, r17, SKIP_RTI
	
	call TRATA_PB
	
	br FIM_RTI
SKIP_RTI:
	# Testa se temporizador
	movi r17, 0x1 # Máscara do IRQ0 (Timer)
	bne et, r17, FIM_RTI # Caso não seja timer, sai da RTI

	call TRATA_TIMER # Chamada da sub-rotina TRATA_TIMER
	
	br FIM_RTI

# Sub-rotina: Tratamento de botões
# r16 => Endereços de BUTTONS e F_CONTADOR
# r17 => Valores dos botões
# r18 => Auxiliar de operações lógicas
TRATA_PB:
	# Store na pilha
	addi sp, sp, -16
	stw ra, 12(sp)
	stw r16, 8(sp)
	stw r17, 4(sp)
	stw r18, 0(sp)
	# Testa se botão 1
	movia r16, BUTTONS
	ldwio r17, 0xC(r16)
	movia r18, 0b10
	bne r18, r17, TESTA_PB2
		# Pausa o contador
		movia r16, F_CONTADOR
		stw r0, 0(r16)
		br FIM_TRATA_PB
TESTA_PB2:
	# Testa se botão 2
	ldwio r17, 0xC(r16)
	movia r18, 0b100
	bne r18, r17, FIM_TRATA_PB
		# Despausa o contador
		movia r16, F_CONTADOR
		movia r17, 0x1
		stw r17, 0(r16)
FIM_TRATA_PB:
	# Reset da captura de borda do botão
	movia r16, BUTTONS
	ldwio r17, 0xC(r16)
	stwio r17, 0xC(r16)
	# Load na pilha
	ldw ra, 12(sp)
	ldw r16, 8(sp)
	ldw r17, 4(sp)
	ldw r18, 0(sp)
	addi sp, sp, 16
	# Retorna para RTI
	ret

# Sub-rotina: Tratamento do temporizador
# Observação: 
# r16 => Endereços de TIMER, F_TIMER, F_CONTADOR, F_ALARME, C1, C2, C3, C4 e RLEDS
# r17 => Valores nos endereços
# r18 => Auxiliar de operações lógicas
# r20 => Valor em C1
# r21 => Valor em C2
# r22 => Valor em C3
# r23 => Valor em C4
TRATA_TIMER:
	# Store na pilha
	addi sp, sp, -32
	stw ra, 28(sp)
	stw r16, 24(sp)
	stw r17, 20(sp)
	stw r18, 16(sp)
	stw r20, 12(sp)
	stw r21, 8(sp)
	stw r22, 4(sp)
	stw r23, 0(sp)
	# Verifica a flag do timer
	movia r16, F_TIMER
	ldw r17, 0(r16)
	bne r17, r0, SKIP_VERIFICA_TIMER
	# Caso flag do timer igual a zero
	movia r17, 0x1
	stw r17, 0(r16)
	br SKIP_TIMER_C4
SKIP_VERIFICA_TIMER:
	# Como flag do timer é diferente de zero
	stw r0, 0(r16)
	# Verifica a flag do contador
	movia r16, F_CONTADOR
	ldw r17, 0(r16)
	beq r17, r0, SKIP_TIMER_C4
	# Update do contador
		# Load dos valores do contador nos registradores
		movia r16, C1
		ldw r20, 0(r16)
		ldw r21, 4(r16)
		ldw r22, 8(r16)
		ldw r23, 12(r16)
		# HEX0
		movia r18, 0x9
		beq r18, r20, SKIP_TIMER_C1
			addi r20, r20, 0x1
			stw r20, 0(r16)
			br SKIP_TIMER_C4
SKIP_TIMER_C1:
		# HEX1
		movia r18, 0x5
		beq r18, r21, SKIP_TIMER_C2
			stw r0, 0(r16)
			addi r21, r21, 0x1
			stw r21, 4(r16)
			br SKIP_TIMER_C4
SKIP_TIMER_C2:
		# HEX2
		movia r18, 0x9
		beq r18, r22, SKIP_TIMER_C3
			stw r0, 0(r16)
			stw r0, 4(r16)
			addi r22, r22, 0x1
			stw r22, 8(r16)
			br SKIP_TIMER_C4
SKIP_TIMER_C3:
		# HEX3
		beq r18, r23, SKIP_TIMER_C4
			stw r0, 0(r16)
			stw r0, 4(r16)
			stw r0, 8(r16)
			addi r23, r23, 0x1
			stw r23, 12(r16)
SKIP_TIMER_C4:
	# Atualização dos displays de 7 segmentos
	call SET_DISPLAYS_CONTADOR
	# Verifica a flag do alarme
	movia r16, F_ALARME
	ldw r17, 0(r16)
	beq r17, r0, SKIP_TIMER_A4
	# Verifica o valor da flag do alarme
	movia r18, 0x1
	bgt r17, r18, SKIP_TIMER_A1
	# Verifica o valor do contador
	movia r16, DISPLAYS
	ldwio r17, 0(r16)
	movia r16, DISPLAYS2
	ldwio r18, 0(r16)
	# Verifica se o contador é igual ao alarme
	bne r17, r18, SKIP_TIMER_A4
	# Aciona o alarme
		# LEDS
		movia r16, RLEDS
		ldwio r17, 0(r16)
		nor r17, r17, r17
		stwio r17, 0(r16)
		# Flag
		movia r16, F_ALARME
		movia r17, 0xc
		stw r17, 0(r16)
	br SKIP_TIMER_A4
SKIP_TIMER_A1:
	# Verifica a flag do timer
	movia r16, F_TIMER
	ldw r17, 0(r16)
	beq r17, r0, SKIP_TIMER_A3
	# Acende os LEDS vermelhos
	movia r16, RLEDS
	movia r17, 0xFFFFFFFF
	stwio r17, 0(r16)
	movia r18, 0x2
	# Verifica se é o último acionamento do alarme
	movia r16, F_ALARME
	ldw r17, 0(r16)
	beq r17, r18, SKIP_TIMER_A2
		# Configura a flag do alarme
		movia r16, F_ALARME
		ldw r17, 0(r16)
		subi r17, r17, 0x1
		stw r17, 0(r16)
		br SKIP_TIMER_A4
SKIP_TIMER_A2:
		# Configuração do alarme no último acionamento
		movia r16, F_ALARME
		movia r17, 0x1
		stw r17, 0(r16)
		movia r16, RLEDS
		stwio r0, 0(r16)
		br SKIP_TIMER_A4
SKIP_TIMER_A3:
	# Desliga os LEDS vermelhos
	movia r16, RLEDS
	stwio r0, 0(r16)
SKIP_TIMER_A4:
	# Reset do timer
	movia r16, TIMER
	movi r17, 0x1
	stwio r17, 0(r16)
	# Load na pilha
	ldw ra, 28(sp)
	ldw r16, 24(sp)
	ldw r17, 20(sp)
	ldw r18, 16(sp)
	ldw r20, 12(sp)
	ldw r21, 8(sp)
	ldw r22, 4(sp)
	ldw r23, 0(sp)
	addi sp, sp, 32
	# Retorna para RTI
	ret

# Final da RTI
SW_EXCEPTION:
FIM_RTI:
	# Load na pilha
	ldw ra, 8(sp)
	ldw r16, 4(sp)
	ldw r17, 0(sp)
	addi sp, sp, 12
	# Retorna para o programa pincipal
	eret

# Programa principal: Inicialização de valor e contém o loop de polling principal
# r8 => Endereços
# r9 => Valores, principalmente do JTAG UART
# r10 => Auxiliar de operações lógicas
# r11 => Endereço do valor de write no JTAG UART
.global _start
_start:
	# Inicíalização da pilha
	movia sp, STACK
	# Inicalização das variáveis na memória
	movia r8, C1
	movia r9, 0x1
	stw r0, 0(r8)
	stw r0, 4(r8)
	stw r0, 8(r8)
	stw r0, 12(r8)
	stw r9, 16(r8)
	stw r9, 20(r8)
	stw r0, 24(r8)
	stw r0, 28(r8)
	# Configuração e habilitação dos dispositivos de I/O e suas interrupções
		# LEDS vermelhos e verdes
		movia r8, RLEDS
		stwio r0, 0(r8)
		movia r8, GLEDS
		stwio r0, 0(r8)
		# Displays de 7 segmentos
		movia r8, DISPLAYS
		stwio r0, 0(r8)
		movia r8, DISPLAYS2
		stwio r0, 0(r8)
		# Switches
		movia r8, SWITCHES
		stwio r0, 0(r8)
		# Botões
			# Captura de borda dos botões
			movia r8, BUTTONS
			ldwio r9, 0xC(r8)
			stwio r9, 0xC(r8)
			# Habilita interrupção dos botões 1 e 2
			movi r9, 0b0110
			stwio r9, 8(r8)
		# Temporizador
			movia r8, TIMER
			# Configura o temporizador para gerar interrupções a cada segundo
			movia r10, 25000000
			# Parte baixa do contador
			andi r9, r10, 0xFFFF
			stwio r9, 8(r8)
			# Parte alta do contador
			srli r9, r10, 16
			stwio r9, 12(r8)
			# Habilita o temporizador
			movi r9, 0b111
			stwio  r9, 4(r8)
	# Habilita as interrupções de IRQ0 (Timer) e IRQ1 (Pushbutton)
	movi  r8, 0b11
   	wrctl ienable, r8
	# Habilita interrupção no processador (PIE)
	movi  r8, 0b1
   	wrctl status, r8
	# Inicialização do console
	call SET_CONSOLE
POLLING_MAIN:
	movia r8, UART
	movia r11, PRINT
	# Load de data
	ldwio r9, 0(r8)
	# Isolamento de RVALID
	andi r10, r9, 0x8000
	beq r10, r0, POLLING_MAIN
	# Isolamento do caractere
	andi r9, r9, 0xFF
	# Comando de saída 'E'
	movia r10, 'E'
	beq r10, r9, FIM_MAIN
	# Comandos 'L'
	movia r10, 'L'
	bne r10, r9, SKIP_MAIN_1
		stw r9, 0(r11)
		call WRITE
		call TRATA_L
		call COMANDO_NEXT
		br POLLING_MAIN
SKIP_MAIN_1:
	# Comandos 'C'
	movia r10, 'C'
	bne r10, r9, POLLING_MAIN
		stw r9, 0(r11)
		call WRITE
		call TRATA_C
		call COMANDO_NEXT
		br POLLING_MAIN
FIM_MAIN:
	stw r9, 0(r11)
	call WRITE
	# Interrompe as interrupções de IRQ0 (Timer) e IRQ1 (Pushbutton)
	movi r8, 0b00
   	wrctl ienable, r8
# Permanece no laço caso fim de execução
FIM:
	br FIM

# Sub-rotina: Exibe a mensagem inicial na janela do terminal e remove resíduos da fila de READ
# r16 => Endereço base de STRING
# r17 => Valores de STRING (byte)
# r18 => Valor WSPACE em control
# r19 => Endereço de JTAG UART
SET_CONSOLE:
	# Store na pilha
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r16, 12(sp)
	stw r17, 8(sp)
	stw r18, 4(sp)
	stw r19, 0(sp)
	# Limpa a fila de leitura de JTAG UART
	call CLEAN_READ
	# Escrita de STRING em JTAG UART
	movia r16, STRING
	mov r17, r0
	movia r19, UART
LOOP_SET:
	# Load do byte de STRING
	ldb r17, 0(r16)
	# Verifica se é o fim de STRING
	beq r17, r0, END_SET
	# Verifica o espaço na fila de escrita
	POLLING_WRITE_SET:
		# Load de control
		ldwio r18, 4(r19)
		# Isolamento de WSPACE
		srli r18, r18, 16
		andi r18, r18, 0xFFFF
		# Caso WSPACE diferente de zero, caractere é impresso no JTAG UART
		beq r18, r0, POLLING_WRITE_SET
		stwio r17, 0(r19)
	addi r16, r16, 1
	br LOOP_SET
END_SET:
	# Load na pilha
	ldw ra, 16(sp)
	ldw r16, 12(sp)
	ldw r17, 8(sp)
	ldw r18, 4(sp)
	ldw r19, 0(sp)
	addi sp, sp, 20
	# Retorno para o caller
	ret

# Sub-rotina: Limpa a fila de leitura de resíduos de execuções anteriores
# r16 => Endereço base de JTAG UART
# r17 => Valores de data
CLEAN_READ:
	# Store na pilha
	addi sp, sp, -12
	stw ra, 8(sp)
	stw r16, 4(sp)
	stw r17, 0(sp)
	# Inicialização dos registradores
	movia r16, UART
# Loop para limpar a fila de leitura do JTAG UART
LOOP_CLEAN:
	# Load de do registrador data do JTAG UART
	ldwio r17, 0(r16)
	# Isolamento de RVALID
	andi r17, r17, 0x8000
	# Se mantém em no loop até consumir todos os caracteres
	beq r17, r0, FIM_CLEAN
	br LOOP_CLEAN
FIM_CLEAN:
	# Load na pilha
	ldw ra, 8(sp)
	ldw r16, 4(sp)
	ldw r17, 0(sp)
	addi sp, sp, 12
	# Retorno para o caller
	ret

# Sub-rotina: Impressão do valor em PRINT no JATG UART
# r16 => Endereço base de JTAG UART
# r17 => Valor do caractere
WRITE:
	# Store na pilha
	addi sp, sp, -12
	stw ra, 8(sp)
	stw r16, 4(sp)
	stw r17, 0(sp)
	# Imprime no JTAG UART
	movia r16, UART
POLLING_WRITE_UART:
	# Load de control
	ldwio r17, 4(r16)
	# Isolamento de WSPACE
	srli r17, r17, 16
	andi r17, r17, 0xFFFF
	# Caso WSPACE diferente de zero, caractere é impresso no JTAG UART
	beq r17, r0, POLLING_WRITE_UART
	# Imprime
	movia r17, PRINT
	ldw r17, 0(r17)
	stwio r17, 0(r16)
	# Load na pilha
	ldw ra, 8(sp)
	ldw r16, 4(sp)
	ldw r17, 0(sp)
	addi sp, sp, 12
	# Retorno para o caller
	ret

# Sub-rotina: Configura os 4 primeiros displays com base nos valores em C1, C2, C3 e C4
# r16 => Endereços de C1, C2, C3, C4 e DISPLAY
# r17 => Valores em C1, C2, C3 e C4
# r18 => Endereço base de TABELA
# r19 => Valor que será colocado nos displays de 7 segmentos
SET_DISPLAYS_CONTADOR:
	# Store na pilha
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r16, 12(sp)
	stw r17, 8(sp)
	stw r18, 4(sp)
	stw r19, 0(sp)
	# Inicialização dos registradores
	movia r16, C1
	addi r16, r16, 0xc
	movia r18, TABELA
	mov r19, r0
# Atualização dos displays de 7 segmentos
LOOP_DISPLAYS_CONTADOR:
	# Busca pelo valor na tabela
	ldw r17, 0(r16)
	muli r17, r17, 0x4
	add r17, r17, r18
	ldw r17, 0(r17)
	# Adição do valor da tabela no registrador dos displays
	or r19, r19, r17
	movia r17, C1
	beq r16, r17, FIM_LOOP_DISPLAYS_CONTADOR
	slli r19, r19, 0x8
	subi r16, r16, 0x4
	br LOOP_DISPLAYS_CONTADOR
FIM_LOOP_DISPLAYS_CONTADOR:
	# Atualização no registrador dos displays
	movia r16, DISPLAYS
	stwio r19, 0(r16)
	# Load na pilha
	ldw ra, 16(sp)
	ldw r16, 12(sp)
	ldw r17, 8(sp)
	ldw r18, 4(sp)
	ldw r19, 0(sp)
	addi sp, sp, 20
	# Retorno para o caller
	ret

# Sub-rotina: Imprime na janela do terminal o separador de comandos
# r16 => Endereço base de PRINT
# r17 => Valor do caractere que será impresso
COMANDO_NEXT:
	# Store na pilha
	addi sp, sp, -12
	stw ra, 8(sp)
	stw r16, 4(sp)
	stw r17, 0(sp)
	# Impressões
	movia r16, PRINT
	movia r17, ' '
	stw r17, 0(r16)
	call WRITE
	movia r17, '|'
	stw r17, 0(r16)
	call WRITE
	movia r17, ' '
	stw r17, 0(r16)
	call WRITE
	# Load na pilha
	ldw ra, 8(sp)
	ldw r16, 4(sp)
	ldw r17, 0(sp)
	addi sp, sp, 12
	# Retorno para o caller
	ret

# Sub-rotina: Tratamento de comandos L
# Observação: Caracteres diferentes de 0, 1, 2, 3, 4 e 5 são desconsiderados
# r16 => Endereço base de JTAG UART
# r17 => Valores dos caracteres
# r18 => Auxiliar de operações lógicas
# r19 => Auxiliar de iteração
TRATA_L:
	# Store na pilha
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r16, 12(sp)
	stw r17, 8(sp)
	stw r18, 4(sp)
	stw r19, 0(sp)
	# Inicialização dos registradores
	movia r16, UART
POLLING_TRATA_L:
	# Load de data
	ldwio r17, 0(r16)
	# Isolamento de RVALID
	andi r18, r17, 0x8000
	beq r18, r0, POLLING_TRATA_L
	# Isolamento do caractere
	andi r17, r17, 0xFF
	# Configuração dos registradores
	movia r18, '0'
	subi r18, r18, 0x1
	movia r19, 0x6
# Loop de caractere
LOOP_TRATA_L:
	# Verifica a iteração
	beq r19, r0, POLLING_TRATA_L
	subi r19, r19, 0x1
	# Verifica o caractere
	addi r18, r18, 0x1
	bne r18, r17, LOOP_TRATA_L
	# Impressões
		# Impressão do caractere
		movia r16, PRINT
		stw r17, 0(r16)
		call WRITE
# Busca pela sub-rotina
	# Comando L0
	movia r18, '0'
	bne r18, r17, SKIP_L0
		# Impressão de Espaço
		movia r17, ' '
		stw r17, 0(r16)
		call WRITE
		# Chamada da sub-rotina
		call COMANDO_L0
		br FIM_TRATA_L
SKIP_L0:
	# Comando L1
	movia r18, '1'
	bne r18, r17, SKIP_L1
		# Impressão de Espaço
		movia r17, ' '
		stw r17, 0(r16)
		call WRITE
		# Chamada da sub-rotina
		call COMANDO_L1
		br FIM_TRATA_L
SKIP_L1:
	# Comando L2
	movia r18, '2'
	bne r18, r17, SKIP_L2
		# Chamada da sub-rotina
		call COMANDO_L2
		br FIM_TRATA_L
SKIP_L2:
	# Comando L3
	movia r18, '3'
	bne r18, r17, SKIP_L3
		# Chamada da sub-rotina
		call COMANDO_L3
		br FIM_TRATA_L
SKIP_L3:
	# Comando L4
	movia r18, '4'
	bne r18, r17, SKIP_L4
		# Chamada da sub-rotina
		call COMANDO_L4
		br FIM_TRATA_L
SKIP_L4:
	# Comando L5
		# Chamada da sub-rotina
		call COMANDO_L5
FIM_TRATA_L:
	# Load na pilha
	ldw ra, 16(sp)
	ldw r16, 12(sp)
	ldw r17, 8(sp)
	ldw r18, 4(sp)
	ldw r19, 0(sp)
	addi sp, sp, 20
	# Retorno para o caller
	ret

# Sub-rotina: Acende o xx-ésimo led verde
# Observação: Caso 1° caractere diferente de 0, é considerada a 9° posição
# r16 => Endereços de JTAG UART, PRINT e GLEDS
# r17 => Valores dos caracteres de JTAG UART
# r18 => Auxiliar de operações lógicas
# r19 => Auxiliar de iteração
COMANDO_L0:
	# Store na pilha
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r16, 12(sp)
	stw r17, 8(sp)
	stw r18, 4(sp)
	stw r19, 0(sp)
	# Inicialização dos registradores
	mov r19, r0
	# Busca pela posição do led verde
POLLING_UART_L0:
	movia r16, UART
	# Load de data
	ldwio r17, 0(r16)
	# Isolamento de RVALID
	andi r16, r17, 0x8000
	beq r16, r0, POLLING_UART_L0
	# Impressão do caractere
	movia r16, PRINT
	stw r17, 0(r16)
	call WRITE
	# Isolamento do número
	andi r17, r17, 0xF
	# Verifica a iteração
	bne r19, r0, SKIP_L0_1
		# Primeiro dígito em r18
		addi r19, r19, 1
		mov r18, r17
		br POLLING_UART_L0
SKIP_L0_1:
		# Branch caso o primeiro dígito seja igual a zero
		beq r18, r0, FIM_POLLING_UART_L0
		movia r17, 0x9
FIM_POLLING_UART_L0:
	# Preparação da máscara de posição
	movia r18, 0x1
	subi r17, r17, 1
	sll r18, r18, r17
	# Acende o LED verde
	movia r16, GLEDS
	ldwio r17, 0(r16)
	or r17, r17, r18
	stwio r17, 0(r16)
	# Load na pilha
	ldw ra, 16(sp)
	ldw r16, 12(sp)
	ldw r17, 8(sp)
	ldw r18, 4(sp)
	ldw r19, 0(sp)
	addi sp, sp, 20
	# Retorno para o caller
	ret

# Sub-rotina: Apaga o xx-ésimo led verde
# Observação: Caso 1° caractere diferente de 0, é considerada a 9° posição
# r16 => Endereços de JTAG UART, PRINT e GLEDS
# r17 => Valores dos caracteres de JTAG UART
# r18 => Auxiliar de operações lógicas
# r19 => Auxiliar de iteração
COMANDO_L1:
	# Store na pilha
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r16, 12(sp)
	stw r17, 8(sp)
	stw r18, 4(sp)
	stw r19, 0(sp)
	# Inicialização dos registradores
	mov r19, r0
	# Busca pela posição do led verde
POLLING_UART_L1:
	movia r16, UART
	# Load de data
	ldwio r17, 0(r16)
	# Isolamento de RVALID
	andi r16, r17, 0x8000
	beq r16, r0, POLLING_UART_L1
	# Impressão do caractere
	movia r16, PRINT
	stw r17, 0(r16)
	call WRITE
	# Isolamento do número
	andi r17, r17, 0xF
	# Verifica a iteração
	bne r19, r0, SKIP_L1_1
		# Primeiro dígito em r18
		addi r19, r19, 1
		mov r18, r17
		br POLLING_UART_L1
SKIP_L1_1:
		# Branch caso o primeiro dígito seja igual a zero
		beq r18, r0, FIM_POLLING_UART_L1
		movia r17, 0x9
FIM_POLLING_UART_L1:
	# Preparação dos registradores
	subi r17, r17, 0x1
	# Apaga o LED verde
	movia r16, GLEDS
	ldwio r18, 0(r16)
	ror r18, r18, r17
	srli r18, r18, 0x1
	slli r18, r18, 0x1
	rol r18, r18, r17
	stwio r18, 0(r16)
	# Load na pilha
	ldw ra, 16(sp)
	ldw r16, 12(sp)
	ldw r17, 8(sp)
	ldw r18, 4(sp)
	ldw r19, 0(sp)
	addi sp, sp, 20
	# Retorno para o caller
	ret

# Sub-rotina: Acende todos os leds pares
# Observação: Caso algum led ímpar estiver aceso, ele será mantido aceso
# r16 => Endereço base de GLEDS
# r17 => Valor que será colocado nos leds verdes
COMANDO_L2:
	# Store na pilha
	addi sp, sp, -12
	stw ra, 8(sp)
	stw r16, 4(sp)
	stw r17, 0(sp)
	# Acende os LEDS verdes pares
	movia r16, GLEDS
	ldwio r17, 0(r16)
	ori r17, r17, 0x155
	stwio r17, 0(r16)
	# Load na pilha
	ldw ra, 8(sp)
	ldw r16, 4(sp)
	ldw r17, 0(sp)
	addi sp, sp, 12
	# Retorno para o caller
	ret

# Sub-rotina: Acende todos os leds ímpares
# Observação: Caso algum led par estiver aceso, ele será mantido aceso
# r16 => Endereço base de GLEDS
# r17 => Valor que será colocado nos leds verdes
COMANDO_L3:
	# Store na pilha
	addi sp, sp, -12
	stw ra, 8(sp)
	stw r16, 4(sp)
	stw r17, 0(sp)
	# Acende os LEDS verdes ímpares
	movia r16, GLEDS
	ldwio r17, 0(r16)
	ori r17, r17, 0xAA
	stwio r17, 0(r16)
	# Load na pilha
	ldw ra, 8(sp)
	ldw r16, 4(sp)
	ldw r17, 0(sp)
	addi sp, sp, 12
	# Retorno para o caller
	ret

# Sub-rotina: O estado dos 9 primeiros switches é refletido nos leds verdes 
# Observação: Leds previamente acesos podem ser apagados dependendo do estado dos switches
# r16 => Endereços de SWITCHES e GLEDS
# r17 => Valor dos switches que será colocado nos leds verdes
COMANDO_L4:
	# Store na pilha
	addi sp, sp, -12
	stw ra, 8(sp)
	stw r16, 4(sp)
	stw r17, 0(sp)
	# Load do conteúdo dos switches
	movia r16, SWITCHES
	ldwio r17, 0(r16)
	# Máscara para apenas os 9 primeiros switches
	andi r17, r17, 0x1FF
	# Acende os LEDS verdes
	movia r16, GLEDS
	stwio r17, 0(r16)
	# Load na pilha
	ldw ra, 8(sp)
	ldw r16, 4(sp)
	ldw r17, 0(sp)
	addi sp, sp, 12
	# Retorno para o caller
	ret

# Sub-rotina: Apaga todos os leds verdes
# r16 => Endereço base de GLEDS
COMANDO_L5:
	# Store na pilha
	addi sp, sp, -8
	stw ra, 4(sp)
	stw r16, 0(sp)
	# Apaga os LEDS verdes
	movia r16, GLEDS
	stwio r0, 0(r16)
	# Load na pilha
	ldw ra, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 8
	# Retorno para o caller
	ret

# Sub-rotina: Tratamento de comandos C
# Observação: Caracteres diferentes de 0, 1 e 2 são desconsiderados
# r16 => Endereço base de JTAG UART
# r17 => Valores dos caracteres
# r18 => Auxiliar de operações lógicas
# r19 => Auxiliar de iteração
TRATA_C:
	# Store na pilha
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r16, 12(sp)
	stw r17, 8(sp)
	stw r18, 4(sp)
	stw r19, 0(sp)
	# Inicialização dos registradores
	movia r16, UART
POLLING_TRATA_C:
	# Load de data
	ldwio r17, 0(r16)
	# Isolamento de RVALID
	andi r18, r17, 0x8000
	beq r18, r0, POLLING_TRATA_C
	# Isolamento do caractere
	andi r17, r17, 0xFF
	# Configuração dos registradores
	movia r18, '0'
	subi r18, r18, 0x1
	movia r19, 0x3
# Loop de caractere
LOOP_TRATA_C:
	# Verifica a iteração
	beq r19, r0, POLLING_TRATA_C
	subi r19, r19, 0x1
	# Verifica o caractere
	addi r18, r18, 0x1
	bne r18, r17, LOOP_TRATA_C
	# Impressões
		# Impressão do caractere
		movia r16, PRINT
		stw r17, 0(r16)
		call WRITE
# Busca pela sub-rotina
	# Comando C0
	movia r18, '0'
	bne r18, r17, SKIP_C0
		# Impressão de Espaço
		movia r17, ' '
		stw r17, 0(r16)
		call WRITE
		# Chamada da sub-rotina
		call COMANDO_C0
		br FIM_TRATA_C
SKIP_C0:
	# Comando C1
	movia r18, '1'
	bne r18, r17, SKIP_C1
		# Impressão de Espaço
		movia r17, ' '
		stw r17, 0(r16)
		call WRITE
		# Chamada da sub-rotina
		call COMANDO_C1
		br FIM_TRATA_C
SKIP_C1:
	# Comando C2
		# Chamada da sub-rotina
		call COMANDO_C2
FIM_TRATA_C:
	# Load na pilha
	ldw ra, 16(sp)
	ldw r16, 12(sp)
	ldw r17, 8(sp)
	ldw r18, 4(sp)
	ldw r19, 0(sp)
	addi sp, sp, 20
	# Retorno para o caller
	ret

# Sub-rotina: Configura o valor do contador
# Observação: Caso o valor do 6° led for maior que 5, ele será reduzido para 5
# r16 => Endereços de F_CONTADOR, JTAG UART, PRINT, C1, C2, C3 e C4
# r17 => Valores dos caracteres
# r18 => Auxiliar de operações lógicas
# r19 => Auxiliar de iteração
COMANDO_C0:
	# Store na pilha
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r16, 12(sp)
	stw r17, 8(sp)
	stw r18, 4(sp)
	stw r19, 0(sp)
	# Pausa o contador
	movia r16, F_CONTADOR
	stw r0, 0(r16)
	# Inicialização dos registradores
	movia r19, 0x4
	# Leitura dos 4 valores
POLLING_UART_C0:
	movia r16, UART
	# Verifica a iteração
	beq r19, r0, FIM_POLLING_UART_C0
	# Load de data
	ldwio r17, 0(r16)
	# Isolamento de RVALID
	andi r18, r17, 0x8000
	beq r18, r0, POLLING_UART_C0
	# Verificação se é número
	# Isolamento do caractere
	andi r17, r17, 0xFF
	# Caso menor que 0
	movia r18, '0'
	blt r17, r18, POLLING_UART_C0
	# Caso maior que 9
	movia r18, '9'
	bgt r17, r18, POLLING_UART_C0
	# Impressão do valor
	movia r16, PRINT
	stw r17, 0(r16)
	call WRITE
	# Isolamento do número
	andi r17, r17, 0xF
	# Update do valor no contador
	# HEX3
	# Verifica a iteração
	movia r18, 0x4
	bne r18, r19, SKIP_C0_1
		# Update de HEX3
		movia r16, C4
		stw r17, 0(r16)
		subi r19, r19, 0x1
		br POLLING_UART_C0
SKIP_C0_1:
	# HEX2
	# Verifica a iteração
	movia r18, 0x3
	bne r18, r19, SKIP_C0_2
		# Update de HEX2
		movia r16, C3
		stw r17, 0(r16)
		subi r19, r19, 0x1
		br POLLING_UART_C0
SKIP_C0_2:	
	# HEX1
	# Verifica a iteração
	movia r18, 0x2
	bne r18, r19, SKIP_C0_4
	# Verifica se número maior que 5
	movia r18, 0x5
	ble r17, r18, SKIP_C0_3
		# Caso número maior que 5, valor é alterado para 5
		movia r17, 0x5
SKIP_C0_3:
		# Update de HEX1
		movia r16, C2
		stw r17, 0(r16)
		subi r19, r19, 0x1
		br POLLING_UART_C0
SKIP_C0_4:
	# HEX0
	# Update de HEX0
	movia r16, C1
	stw r17, 0(r16)
	subi r19, r19, 0x1
	br POLLING_UART_C0
FIM_POLLING_UART_C0:
	# Despausa o contador
	movia r16, F_CONTADOR
	movia r17, 0x1
	stw r17, 0(r16)
	# Configuração do timer
	movia r16, F_TIMER
	stw r0, 0(r16)
	# Load na pilha
	ldw ra, 16(sp)
	ldw r16, 12(sp)
	ldw r17, 8(sp)
	ldw r18, 4(sp)
	ldw r19, 0(sp)
	addi sp, sp, 20
	# Retorno para o caller
	ret

# Sub-rotina: Configura e habilita o alarme
# Observação: Caso o valor do 2° led for maior que 5, ele será reduzido para 5
# r16 => Endereços de JTAG UART, PRINT, DISPLAYS2, F_TIMER e F_ALARME
# r17 => Valores dos caracteres de JTAG UART e da TABELA
# r18 => Auxiliar de operações lógicas
# r19 => Auxiliar de iteração
# r20 => Valor que será colocado nos 4 displays à esquerda
COMANDO_C1:
	# Store na pilha
	addi sp, sp, -24
	stw ra, 20(sp)
	stw r16, 16(sp)
	stw r17, 12(sp)
	stw r18, 8(sp)
	stw r19, 4(sp)
	stw r20, 0(sp)
	# Inicialização dos registradores
	movia r19, 0x4
	mov r20, r0
	# Leitura dos 4 valores
POLLING_UART_C1:
	movia r16, UART
	# Verifica a iteração
	beq r19, r0, FIM_POLLING_UART_C1
	# Load de data
	ldwio r17, 0(r16)
	# Isolamento de RVALID
	andi r18, r17, 0x8000
	beq r18, r0, POLLING_UART_C1
	# Verificação se é número
	# Isolamento do caractere
	andi r17, r17, 0xFF
	# Caso menor que 0
	movia r18, '0'
	blt r17, r18, POLLING_UART_C1
	# Caso maior que 9
	movia r18, '9'
	bgt r17, r18, POLLING_UART_C1
	# Impressão do valor
	movia r16, PRINT
	stw r17, 0(r16)
	call WRITE
	# Isolamento do número
	andi r17, r17, 0xF
	# Configuração do alarme
	# Verifica a iteração
	movia r18, 0x2
	bne r18, r19, SKIP_C1_1
	# Verifica se número maior que 5
	movia r18, 0x5
	ble r17, r18, SKIP_C1_1
		# Caso número maior que 5, valor é alterado para 5
		movia r17, 0x5
SKIP_C1_1:
	# Busca pelo valor na tabela
	muli r17, r17, 0x4
	addi r17, r17, TABELA
	ldw r17, 0(r17)
	# Adição do valor da tabela no registrador dos displays
	or r20, r20, r17
	# Verifica a iteração
	movia r18, 0x1
	beq r18, r19, SKIP_C1_2
		# Caso última iteração, não ocorre o deslocamento de bits
		slli r20, r20, 0x8
SKIP_C1_2:
	# Configuração do iterator
	subi r19, r19, 0x1
	br POLLING_UART_C1
FIM_POLLING_UART_C1:
	# Atualização dos displays
	movia r16, DISPLAYS2
	stwio r20, 0(r16)
	# Configuração das flags
	movia r16, F_TIMER
	stw r0, 0(r16)
	movia r16, F_ALARME
	movia r17, 0x1
	stw r17, 0(r16)
	# Load na pilha
	ldw ra, 20(sp)
	ldw r16, 16(sp)
	ldw r17, 12(sp)
	ldw r18, 8(sp)
	ldw r19, 4(sp)
	ldw r20, 0(sp)
	addi sp, sp, 24
	# Retorno para o caller
	ret

# Sub-rotina: Zera e desabilita o alarme
# r16 => Endereços de F_ALARME, DISPLAYS2 e RLEDS
COMANDO_C2:
	# Store na pilha
	addi sp, sp, -8
	stw ra, 4(sp)
	stw r16, 0(sp)
	# Zera a flag do alarme
	movia r16, F_ALARME
	stw r0, 0(r16)
	# Limpa os displays de 7 segmentos
	movia r16, DISPLAYS2
	stwio r0, 0(r16)
	# Limpa os LEDS vermelhos
	movia r16, RLEDS
	stwio r0, 0(r16)
	# Load na pilha
	ldw ra, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 8
	# Retorno para o caller
	ret

TABELA:
# Tabela de valores dos displays de 7 segmentos
.word 0x3F # 0
.word 0x06 # 1
.word 0x5B # 2
.word 0x4F # 3
.word 0x66 # 4
.word 0x6D # 5
.word 0x7D # 6
.word 0x07 # 7
.word 0x7F # 8
.word 0x6F # 9

STRING:
	.asciz "Entre com o comando: "

.end