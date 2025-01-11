CREATE OR REPLACE PROCEDURE ForecastProcess(Project VARCHAR(12), Amount NUMERIC(10, 2), StartDay DATE, Duration INT) AS
$$
	DECLARE
		EfToHom 						INT[] = ARRAY[ 7, 14, 25, 30, 35, 55,  60,  65,  70,  80,  90,  95];
		HomToGo 						INT[] = ARRAY[16, 28, 45, 70, 85, 95, 115, 135, 160, 175, 190, 210];
		GoToEnd 						INT[] = ARRAY[ 5, 16, 20, 20, 20, 30,  35,  40,  40,  45,  50,  55];
		
		MonthStart						INT;
		MonthEfToHom					INT;
		MonthHomToGo					INT;
		MonthGoToEnd					INT;
		
		-- Taxas base.
		EfRate							NUMERIC(10, 2) = 0.40;
		HomRate							NUMERIC(10, 2) = 0.50;
		GoRate							NUMERIC(10, 2) = 0.10;
		-- Taxas para reclassificação.
		HomGoReclassRate				NUMERIC(10, 2) = 0.75;
		GoEndReclassRate				NUMERIC(10, 2) = 0.25;
		-- Valor de correção.
		CorrectionValue					NUMERIC(10, 2) = 3.00;
		
		DateAux							DATE;
		NumberAux						NUMERIC(10, 2);
		MonthExpectedValueAux			NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];	
		MonthExecutedValueAux			NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		
		BaseValueEf						NUMERIC(10, 2);
		BaseValueHom					NUMERIC(10, 2);
		BaseValueEnd					NUMERIC(10, 2);
		
		MensalValueEf					NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		MensalValueHom					NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		MensalValueEnd					NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		
		ApliedMonthEf					INT[] = ARRAY[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		ApliedMonthHom					INT[] = ARRAY[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		ApliedMonthEnd					INT[] = ARRAY[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		
		ReclassifiedBalanceEF			NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		ReclassifiedBalanceHom			NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		ReclassifiedBalanceEnd			NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		
		ReclassifiedDifferenceEf		NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		ReclassifiedDifferenceHom		NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		ReclassifiedDifferenceEnd		NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		
		PostLaunchBalance				NUMERIC[] = ARRAY[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
		NeedToReclassifyBalance			VARCHAR(3)[]=ARRAY['Não', 'Não', 'Não', 'Não', 'Não', 'Não', 'Não', 'Não', 'Não', 'Não', 'Não', 'Não'];
		
	BEGIN
		/* Primeiro passo: definir o calendário da demanda. */
		-- Inicializo a variável auxiliar com a data retornada.
		DateAux = StartDay;
		
		-- Extraio o mês de início da demanda.
		MonthStart = EXTRACT(MONTH FROM DateAux)::INT;
		
		-- Incremento os dias passados de Especificação para Homologação.
		DateAux = DateAux + EfToHom[Duration];
		
		-- Extraio o mês em que a especificação será terminada e a homologação será iniciada.
		MonthEfToHom = EXTRACT(MONTH FROM DateAux)::INT;
		
		-- Incremento os dias passados na homologação para o go-live.
		DateAux = DateAux + HomToGo[Duration];
		
		-- Extraio o mês em que a homologação será terminada e o go-live será iniciado.
		MonthHomToGo = EXTRACT(MONTH FROM DateAux)::INT;
		
		-- Incremento os últimos dias para finalização do projeto.
		DateAux = DateAux + GoToEnd[Duration];
		
		-- Por fim extraio o mês em que o projeto será finalizado.
		MonthGoToEnd = EXTRACT(MONTH FROM DateAux)::INT;
		
		/* Tendo já definido o cronograma da demanda em questão, nos partiremos aos cálculos. */
		-- A primeira fase decorre do cálculo do valor base para as fases de Desenvolvimento, Homologação e Encerramento.
		BaseValueEf  = (EfRate) * (Amount) * (1.00/(MonthEfToHom - MonthStart   +1));
		BaseValueHom = (HomRate)* (Amount) * (1.00/(MonthHomToGo - MonthEfToHom +1));
		BaseValueEnd = (GoRate) * (Amount) * (1.00/(MonthGoToEnd - MonthHomToGo +1));
		
		-- Outro passo importante e manter em mente o valor do saldo para cada mês, e inicialmente (sem lançamentos) o saldo equivale ao custo da demanda:
		PostLaunchBalance[1] = Amount;
		
		/* Partiremos agora para a avaliação do primeiro mês. */
		-- Avaliamos se janeiro pertence ao cronograma de execução da demanda:
		IF(MonthStart <= 1 AND 1 <= MonthGoToEnd) THEN
			-- Alteramos a tabela de forecast, informando que aquele mês em especial deveria possuir cálculo de valor.
			UPDATE ForecastProcess SET ApliedJanuary = TRUE WHERE ProjectID = Project;
			
			-- Após isso, cálculamos as quantidades de meses em que o forecast deve ser feito.
			ApliedMonthEf[1]  = MonthEfToHom - MonthStart + 1;
			ApliedMonthHom[1] = MonthHomToGo - MonthEfToHom + 1;
			ApliedMonthEnd[1] = MonthGoToEnd - MonthHomToGo + 1;
		ELSE
			--Em caso do mês de janeiro não pertencer ao cronograma, informamos a sua ausência:
			UPDATE ForecastProcess SET ApliedJanuary = FALSE WHERE ProjectID = Project;
			
			-- E posteriormente deixamos um valor de aviso para esse:
			ApliedMonthEf[1]  = -1;
			ApliedMonthHom[1] = -1;
			ApliedMonthEnd[1] = -1;
		END IF;
		
		-- Dado que Janeiro é o começo do processo de Forecest, ele não terá necessidade de reprogramar o cálculo das taxas base.
		NeedToReclassifyBalance[1] = 'Não';
		
		-- Após isso seguiremos com a avaliação das taxas bases para o primeiro mês.
		IF(NeedToReclassifyBalance[1] = 'Não') THEN
			ReclassifiedBalanceEF[1]  = BaseValueEf;
			ReclassifiedBalanceHom[1] = BaseValueHom;
			ReclassifiedBalanceEnd[1] = BaseValueEnd;
		END IF;
		
		-- Com a mesma conclusão, as taxas aplicadas para Janeiro são equivalentes as taxas base ou taxas de reclassificação:
		IF(NeedToReclassifyBalance[1] = 'Não') THEN
			MensalValueEf[1]  = BaseValueEf;
			MensalValueHom[1] = BaseValueHom;
			MensalValueEnd[1] = BaseValueEnd;
		END IF;
		
		/* Com a determinação dos valores base, faremos a seguinte atribuição: */
		-- Avaliamos se Janeiro fazia parte do cronograma de lançamentos.
		IF(MonthStart <= 1 AND 1 <= MonthGoToEnd) THEN
			-- Seguimos com a avaliação de quais etapas são entendidas no mês de Janeiro:
			-- Primeira: fase de especificação:
			IF(MonthStart <= 1 AND 1 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[1];
			END IF;
			
			-- Segunda: fase de homologação:
			IF(MonthEfToHom <= 1 AND 1 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[1];
			END IF;
			
			-- Terceira: fase de finalização:
			IF(MonthHomToGo <= 1 AND 1 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[1];
			END IF;
			
			-- Finalizado o cálculo do quão é esperado no mês em uma varíavel que pode ser avaliada posteriormente no código:
			MonthExpectedValueAux[1] = NumberAux;
			
			-- Tendo realizado o cálculo do valor esperado para o mês, informamos esse para o usuário.
			UPDATE ForecastProcess SET PrevisionJanuary = MonthExpectedValueAux[1] WHERE ProjectId = Project;
		
		-- Caso Janeiro não pertença ao cronograma de execução, setamos o valor de previsão como zero 0.
		ELSE
			UPDATE ForecastProcess SET PrevisionJanuary = 0 WHERE ProjectId = Project;
		END IF;
		
		/* A partir desse ponto temos os maiores problemas envolvidos nessa lógica de previsão de gastos.
		Esses problemas decorrem em como perceber a existência de lançamentos financeiros ou não e como cálcular
		as novas taxas. */
		
		/* A primeira fase é definir a continuidade do cronograma para os meses subsequentes. */
		-- Para isso, precisamos fazer a avaliação considerando o mês seguinte (Fevereiro nesse caso).
		-- Avaliamos se fevereiro pertencia ao cronograma de execução da demanda.
		IF(MonthStart <= 2 AND 2 <= MonthGoToEnd) THEN
			-- Como fevereiro pertence ao cronograma de execução, avisaremos ao usuário.
			UPDATE ForecastProcess SET ApliedFebruary = TRUE WHERE ProjectID = Project;
			
			-- Avaliamos então se esse mês é só uma continuação para o mês anterior.
			IF(ApliedMonthEf[1] <> -1 AND ApliedMonthHom[1] <> -1 AND ApliedMonthEnd[1] <> -1) THEN
				-- Primeira fase, garantir que a fase de especificação ainda é válida.
				IF(ApliedMonthEf[1]>=2) THEN
					ApliedMonthEf[2] = ApliedMonthEf[1]-1;
					ApliedMonthHom[2]= ApliedMonthHom[1];
					ApliedMonthEnd[2]= ApliedMonthEnd[1];
					
				ELSIF(ApliedMonthHom[1]>=2) THEN
					ApliedMonthEf[2] = 0;
					ApliedMonthHom[2]= ApliedMonthHom[1]-1;
					ApliedMonthEnd[2]= ApliedMonthEnd[1];
				
				ELSIF(ApliedMonthEnd[1]>=2) THEN
					ApliedMonthEf[2] = 0;
					ApliedMonthHom[2]= 0;
					ApliedMonthEnd[2]= ApliedMonthEnd[1]-1;
				
				ELSE
					ApliedMonthEf[2] = 0;
					ApliedMonthHom[2]= 0;
					ApliedMonthEnd[2]= 0;
				
				END IF;
			ELSE
				-- No caso do mês de fevereiro pertencer ao cronograma de execução e janeiro não. Entedemos que a demanda é iniciada em Fevereiro.
				-- Nessa condição cálculamos os períodos de execução para o projeto.
				ApliedMonthEf[2]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[2] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[2] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			--Em caso do mês de fevereiro não pertencer ao cronograma, informamos a sua ausência:
			UPDATE ForecastProcess SET ApliedFebruary = FALSE WHERE ProjectID = Project;
			
			-- E posteriormente deixamos um valor de aviso para esse:
			ApliedMonthEf[2]  = -1;
			ApliedMonthHom[2] = -1;
			ApliedMonthEnd[2] = -1;
		END IF;
		
		-- A Segunda parte desses problemas podem ser resolvidos ao avaliarmos se houve algum lançamento.
		-- Para essa resolução avaliamos a quantidade de linhas de lançamento existentes:
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 1 AND ProjectId = Project;
		
		-- Avaliamos se nós tivemos algum lançamento:
		IF(NumberAux = 0) THEN
			-- Caso esse retorno seja nulo, entenderemos esse como se não houvesse lançamentos. Nesse caso, não será preciso 
			-- reclassificar a diferença entre o esperado e o real (de janeiro (1) para fevereiro (2)).
			ReclassifiedDifferenceEf[1] = 0.00;
			ReclassifiedDifferenceHom[1]= 0.00;
			ReclassifiedDifferenceEnd[1]= 0.00;
			
			-- Bem como não haverá diferença entre o custo da demanda e o seu saldo.
			PostLaunchBalance[2] = PostLaunchBalance[1];
			
			-- A última variável existente nesse, é relativa ao valor desses lançamentos:
			MonthExecutedValueAux[1] = 0;
			-- A qual zeramos, por motivos autoexplicativos.
			
		ELSIF(NumberAux >= 1) THEN
			-- Nesse caso em específico, ocorreram lançamentos financeiros e nós precisamos ter em mente o quanto foi lançado
			-- naquele dado mês.
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 1 AND ProjectId = Project;
			
			MonthExecutedValueAux[1] = NumberAux;
			
			-- Tendo obtido o valor desse lançamento, reduzimos esse do saldo do projeto:
			PostLaunchBalance[2] = PostLaunchBalance[1] - MonthExecutedValueAux[1];
			-- E fazemos a confirmação de que, ainda, temos saldo para continuar com ele:
			IF(PostLaunchBalance[2] <= 0.00) THEN
				PostLaunchBalance[2] = 0.00;
			END IF;
			
			-- Observamos a diferença entre o executado e o que era esperado naquele mês.
			NumberAux = MonthExpectedValueAux[1] - MonthExecutedValueAux[1];
			
			-- E assim definimos o quão, dessa diferença, deve ser reclassificado nos meses posteriores.
			-- Avaliamos se o mês de fevereiro terá cronograma para o projeto:
			IF(ApliedMonthEf[2] <> -1 AND ApliedMonthHom[2] <> -1 AND ApliedMonthEnd[2] <> -1) THEN
				-- Se fevereiro tem ação necessária, avaliamos as fases aplicadas para ele:
				-- Ainda executamos a EF -> HOM:
				/* Lembrando aqui que (NumberAux) nesse momento contém a diferença entre o Esperado e o Executado */
				IF(ApliedMonthEf[2]>0) THEN
					ReclassifiedDifferenceEf[1] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[2]));
					ReclassifiedDifferenceHom[1]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[2]));
					ReclassifiedDifferenceEnd[1]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[2]));
				
				-- Não mais executamos EF->HOM, mas executamos HOM->GO
				ELSIF(ApliedMonthHom[2]>0) THEN
					ReclassifiedDifferenceEf[1] = 0;
					ReclassifiedDifferenceHom[1]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[2]));
					ReclassifiedDifferenceEnd[1]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[2]));
				
				-- A demanda está na última fase GO->END
				ELSE
					ReclassifiedDifferenceEf[1] = 0;
					ReclassifiedDifferenceHom[1]= 0;
					ReclassifiedDifferenceEnd[1]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[2]));
				END IF;
				
			ELSE
				-- Caso não haja meses aplicados para fevereiro, entenderemos que não é preciso reclassificar a diferença (de janeiro) nele (em fevereiro).
				ReclassifiedDifferenceEf[1] = 0.00;
				ReclassifiedDifferenceHom[1]= 0.00;
				ReclassifiedDifferenceEnd[1]= 0.00;
			END IF;
			
		END IF;
		
		/* Nesse momento fizemos a avaliação dos lançamentos e obtivemos os valores para o lançamentos do mês de Janeiro. 
		   Agora fazemos, invariavelmente, a reclassificação do saldo. */
		-- Avaliamos se o mês de fevereiro terá cronograma para o projeto.
		IF(ApliedMonthEf[2] <> -1 AND ApliedMonthHom[2] <> -1 AND ApliedMonthEnd[2] <> -1) THEN
			-- A fase de EF ainda é válida:
			IF(ApliedMonthEf[2]>0) THEN
				ReclassifiedBalanceEF[2]  = (EfRate) * (PostLaunchBalance[2]) * (1.00/ (ApliedMonthEf[2]));
				ReclassifiedBalanceHom[2] = (HomRate)* (PostLaunchBalance[2]) * (1.00/(ApliedMonthHom[2]));
				ReclassifiedBalanceEnd[2] = (GoRate) * (PostLaunchBalance[2]) * (1.00/(ApliedMonthEnd[2]));
			
			-- A fase de EF foi finalizada, mas HOM ainda é válida.
			ELSIF(ApliedMonthHom[2]>0) THEN
				ReclassifiedBalanceEF[2]  = 0;
				ReclassifiedBalanceHom[2] = (HomGoReclassRate) * (PostLaunchBalance[2]) * (1.00/(ApliedMonthHom[2]));
				ReclassifiedBalanceEnd[2] = (GoEndReclassRate) * (PostLaunchBalance[2]) * (1.00/(ApliedMonthEnd[2]));
				
			-- As fases de EF e Hom foram finalizadas, mas GO ainda é válido.
			ELSIF(ApliedMonthEnd[2]>0) THEN
				ReclassifiedBalanceEF[2]  = 0;
				ReclassifiedBalanceHom[2] = 0;
				ReclassifiedBalanceEnd[2] = (100.00/100.00) * (PostLaunchBalance[2]) * (1.00/(ApliedMonthEnd[2]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[2]  = BaseValueEf;
			ReclassifiedBalanceHom[2] = BaseValueHom;
			ReclassifiedBalanceEnd[2] = BaseValueEnd;
		END IF;
		
		/*
		A nossa última discussão se traduzia em relação a existência de lançamentos para o mês de janeiro e como reclassificar a diferença entre o Esperado e o Executado
		nos meses seguintes. Agora continuaremos com essa discussão, mas voltados ao entendimento dos lançamentos esperados para o mês de fevereiro.
		-- Para fazer essa discussão, precisamos retornar a avaliação dos lançamentos de janeiro e com isso observar se devemos refazer o cálculo das taxas base mensais,
		-- ou se nós faremos a reclassificação da diferença.
		*/
		-- Essa discussão se inicia com a retomada dos lançamentos de janeiro:
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 1 AND ProjectId = Project;
		
		
		-- Precisamos reclassificar o saldo: NeedToReclassifyBalance[2]
		IF(NumberAux>0) THEN
			-- Se tivemos lançamentos, vemos o quão maiores eles são comparados com o valor esperado OU avaliamos se ainda temos saldo em um mês.
			IF(MonthExecutedValueAux[1] > CorrectionValue*MonthExpectedValueAux[1] OR PostLaunchBalance[2] = 0) THEN
				-- Se for muito superior OU não temos mais saldo, precisamos refazer o cálculo das taxas base.
				NeedToReclassifyBalance[2] = 'Sim';
			ELSE
				-- Caso contrário, não precisamos refazer esse cálculo.
				NeedToReclassifyBalance[2] = 'Não';
			END IF;
		ELSE
			-- Se não tivemos lançamentos em janeiro, não precisamos reclassificar a diferença de saldo.
			NeedToReclassifyBalance[2] = 'Não';
		END IF;
		
		-- Qual a taxa base devo utilizar: MensalValue
		IF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[2]  = ReclassifiedBalanceEF[2];
			MensalValueHom[2] = ReclassifiedBalanceHom[2];
			MensalValueEnd[2] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[2]  = ReclassifiedBalanceEF[1];
			MensalValueHom[2] = ReclassifiedBalanceHom[1];
			MensalValueEnd[2] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[2]  = BaseValueEf;
			MensalValueHom[2] = BaseValueHom;
			MensalValueEnd[2] = BaseValueEnd;
		END IF;
		
		-- Por fim, para chegarmos no valor a ser reclassificado em fevereiro, fazemos a soma dos valores aplicados para fevereiro:
		IF(MonthStart <= 2 AND 2 <= MonthGoToEnd) THEN
			--Setar novamente a variável
			NumberAux = 0;
			
			-- Primeira: fase de especificação.
			IF(MonthStart <= 2 AND 2 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[2];
			END IF;
			
			-- Segunda: fase de homologação:
			IF(MonthEfToHom <= 2 AND 2 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[2];
			END IF;
			
			-- Terceira: fase de finalização:
			IF(MonthHomToGo <= 2 AND 2 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[2];
			END IF;
			
			-- Agora que fizemos avalaição de fases, faremos algo similar para a reclassificação da diferença:
			-- Primeiro, precisamos reclassificar o saldo?
			IF(NeedToReclassifyBalance[2] = 'Não') THEN
				-- Aqui sabemos que não, então fazemos a avaliação de fases:
				-- Fase de EF
				IF(MonthStart <= 2 AND 2 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
				END IF;
			
				-- Fase de Homologação:
				IF(MonthEfToHom <= 2 AND 2 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
				END IF;
			
				-- Fase de Go-live/Finalização:
				IF(MonthHomToGo <= 2 AND 2 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
				END IF;
			END IF;
			
			-- Finalizado o cálculo do quão é esperado no mês em uma varíavel que pode ser avaliada posteriormente no código:
			MonthExpectedValueAux[2] = NumberAux;
			
			-- Tendo realizado o cálculo do valor esperado para o mês, informamos esse para o usuário.
			UPDATE ForecastProcess SET PrevisionFebruary = MonthExpectedValueAux[2] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionFebruary = 0 WHERE ProjectId = Project;
		END IF;
		
		/*
		Nós, a partir desse ponto, chegamos em uma situação repetitiva. 
		A verdade é que todos os meses de agora em diante, usarão a lógica aplicada para fevereiro.
		Tendo isso em mente, esse será (muito provavelmente) o último comentário aplicado para esse procedimento e seguiremos com os códigos de maneira mais fluída.
		Agradecemos a sua compreensão e paciência e esperamos que a documentação seja útil para a manutenção desse código.
		*/
		
		/* ********************************************************************************************************************************************************************** */
		/* MARÇO */
		IF(MonthStart <= 3 AND 3 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedMarch = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[2] <> -1 AND ApliedMonthHom[2] <> -1 AND ApliedMonthEnd[2] <> -1) THEN
				IF(ApliedMonthEf[2]>=2) THEN
					ApliedMonthEf[3] = ApliedMonthEf[2]-1;
					ApliedMonthHom[3]= ApliedMonthHom[2];
					ApliedMonthEnd[3]= ApliedMonthEnd[2];
					
				ELSIF(ApliedMonthHom[2]>=2) THEN
					ApliedMonthEf[3] = 0;
					ApliedMonthHom[3]= ApliedMonthHom[2]-1;
					ApliedMonthEnd[3]= ApliedMonthEnd[2];
				
				ELSIF(ApliedMonthEnd[2]>=2) THEN
					ApliedMonthEf[3] = 0;
					ApliedMonthHom[3]= 0;
					ApliedMonthEnd[3]= ApliedMonthEnd[2]-1;
				
				ELSE
					ApliedMonthEf[3] = 0;
					ApliedMonthHom[3]= 0;
					ApliedMonthEnd[3]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[3]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[3] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[3] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedMarch = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[3]  = -1;
			ApliedMonthHom[3] = -1;
			ApliedMonthEnd[3] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 2 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[2] = 0.00;
			ReclassifiedDifferenceHom[2]= 0.00;
			ReclassifiedDifferenceEnd[2]= 0.00;
			
			PostLaunchBalance[3] = PostLaunchBalance[2];

			MonthExecutedValueAux[2] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 2 AND ProjectId = Project;
			
			MonthExecutedValueAux[2] = NumberAux;
			
			PostLaunchBalance[3] = PostLaunchBalance[2] - MonthExecutedValueAux[2];
			IF(PostLaunchBalance[3] <= 0.00) THEN
				PostLaunchBalance[3] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[2] - MonthExecutedValueAux[2];
		
		
			IF(ApliedMonthEf[3] <> -1 AND ApliedMonthHom[3] <> -1 AND ApliedMonthEnd[3] <> -1) THEN
				IF(ApliedMonthEf[3]>0) THEN
					ReclassifiedDifferenceEf[2] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[3]));
					ReclassifiedDifferenceHom[2]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[3]));
					ReclassifiedDifferenceEnd[2]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[3]));
				ELSIF(ApliedMonthHom[3]>0) THEN
					ReclassifiedDifferenceEf[2] = 0;
					ReclassifiedDifferenceHom[2]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[3]));
					ReclassifiedDifferenceEnd[2]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[3]));
				ELSE
					ReclassifiedDifferenceEf[2] = 0;
					ReclassifiedDifferenceHom[2]= 0;
					ReclassifiedDifferenceEnd[2]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[3]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[2] = 0.00;
				ReclassifiedDifferenceHom[2]= 0.00;
				ReclassifiedDifferenceEnd[2]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[3] <> -1 AND ApliedMonthHom[3] <> -1 AND ApliedMonthEnd[3] <> -1) THEN
			IF(ApliedMonthEf[3]>0) THEN
				ReclassifiedBalanceEF[3]  = (EfRate) * (PostLaunchBalance[3]) * (1.00/ (ApliedMonthEf[3]));
				ReclassifiedBalanceHom[3] = (HomRate)* (PostLaunchBalance[3]) * (1.00/(ApliedMonthHom[3]));
				ReclassifiedBalanceEnd[3] = (GoRate) * (PostLaunchBalance[3]) * (1.00/(ApliedMonthEnd[3]));
			ELSIF(ApliedMonthHom[3]>0) THEN
				ReclassifiedBalanceEF[3]  = 0;
				ReclassifiedBalanceHom[3] = (HomGoReclassRate) * (PostLaunchBalance[3]) * (1.00/(ApliedMonthHom[3]));
				ReclassifiedBalanceEnd[3] = (GoEndReclassRate) * (PostLaunchBalance[3]) * (1.00/(ApliedMonthEnd[3]));
			ELSIF(ApliedMonthEnd[3]>0) THEN
				ReclassifiedBalanceEF[3]  = 0;
				ReclassifiedBalanceHom[3] = 0;
				ReclassifiedBalanceEnd[3] = (100.00/100.00) * (PostLaunchBalance[3]) * (1.00/(ApliedMonthEnd[3]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[3]  = BaseValueEf;
			ReclassifiedBalanceHom[3] = BaseValueHom;
			ReclassifiedBalanceEnd[3] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 2 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[2] > CorrectionValue*MonthExpectedValueAux[2] OR PostLaunchBalance[3] = 0) THEN
				NeedToReclassifyBalance[3] = 'Sim';
			ELSE
				NeedToReclassifyBalance[3] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[3] = 'Não';
		END IF;
		
		
		IF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[3]  = ReclassifiedBalanceEF[3];
			MensalValueHom[3] = ReclassifiedBalanceHom[3];
			MensalValueEnd[3] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[3]  = ReclassifiedBalanceEF[2];
			MensalValueHom[3] = ReclassifiedBalanceHom[2];
			MensalValueEnd[3] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[3]  = ReclassifiedBalanceEF[1];
			MensalValueHom[3] = ReclassifiedBalanceHom[1];
			MensalValueEnd[3] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[3]  = BaseValueEf;
			MensalValueHom[3] = BaseValueHom;
			MensalValueEnd[3] = BaseValueEnd;
		END IF;
		
		
		IF(MonthStart <= 3 AND 3 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 3 AND 3 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[3];
			END IF;
			
			IF(MonthEfToHom <= 3 AND 3 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[3];
			END IF;
			
			IF(MonthHomToGo <= 3 AND 3 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[3];
			END IF;
			
			/*
			Oi, oi... Ao desenvolvedor lendo essas linhas de código.
			Estou ciente que previamente disse que não faria muitos novos comentários, mas é que essa é a única parte incremental na lógica e julguei ser necessário explica-la.
			*/
			-- Se você chegou até aqui, sabe que em um mês nos somamos os valores de fases aplicados dentro dele e posteriormente fazemos a adição do que reclassificamos 
			-- entre esperado e executado do mês anterior. Então mais para explicar algo simples: Quando fazemos a reclassificação dessa diferença, ela depende da necessidade
			-- de reclassificar o saldo (NeedToReclassifyBalance) daquele mês em especifico mas ela também depende de NÃO reclassificarmos o saldo nos próximos meses.
			-- Em outras palavras: a reclassificação da diferença de fevereiro depende de NÃO reclassificar o saldo em março, bem como a reclassificação da diferença de 
			-- janeiro depende de NÃO reclassificar o saldo em fevereiro. O quê vai diferenciar essas é que janeiro também depende de NÃO reclassificarmos o saldo em março
			-- e assim é dado sucessivamente e de forma incremental.
			-- Desssa forma podemos montar a lógica:
			
			IF(NeedToReclassifyBalance[3] = 'Não') THEN
				IF(MonthStart <= 3 AND 3 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
				END IF;
				
				IF(MonthEfToHom <= 3 AND 3 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
				END IF;
				
				IF(MonthHomToGo <= 3 AND 3 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
				END IF;
				
				
				IF(NeedToReclassifyBalance[2] = 'Não') THEN
					IF(MonthStart <= 3 AND 3 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
					END IF;
					
					IF(MonthEfToHom <= 3 AND 3 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
					END IF;
					
					IF(MonthHomToGo <= 3 AND 3 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
					END IF;
				END IF;
			
			END IF;
			

			MonthExpectedValueAux[3] = NumberAux;

			UPDATE ForecastProcess SET PrevisionMarch = MonthExpectedValueAux[3] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionMarch = 0 WHERE ProjectId = Project;
		END IF;
		
		/* ********************************************************************************************************************************************************************** */
		/* ABRIL */
		IF(MonthStart <= 4 AND 4 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedApril = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[3] <> -1 AND ApliedMonthHom[3] <> -1 AND ApliedMonthEnd[3] <> -1) THEN
				IF(ApliedMonthEf[3]>=2) THEN
					ApliedMonthEf[4] = ApliedMonthEf[3]-1;
					ApliedMonthHom[4]= ApliedMonthHom[3];
					ApliedMonthEnd[4]= ApliedMonthEnd[3];
					
				ELSIF(ApliedMonthHom[3]>=2) THEN
					ApliedMonthEf[4] = 0;
					ApliedMonthHom[4]= ApliedMonthHom[3]-1;
					ApliedMonthEnd[4]= ApliedMonthEnd[3];
				
				ELSIF(ApliedMonthEnd[3]>=2) THEN
					ApliedMonthEf[4] = 0;
					ApliedMonthHom[4]= 0;
					ApliedMonthEnd[4]= ApliedMonthEnd[3]-1;
				
				ELSE
					ApliedMonthEf[4] = 0;
					ApliedMonthHom[4]= 0;
					ApliedMonthEnd[4]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[4]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[4] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[4] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedApril = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[4]  = -1;
			ApliedMonthHom[4] = -1;
			ApliedMonthEnd[4] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 3 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[3] = 0.00;
			ReclassifiedDifferenceHom[3]= 0.00;
			ReclassifiedDifferenceEnd[3]= 0.00;
			
			PostLaunchBalance[4] = PostLaunchBalance[3];

			MonthExecutedValueAux[3] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 3 AND ProjectId = Project;
			
			MonthExecutedValueAux[3] = NumberAux;
			
			PostLaunchBalance[4] = PostLaunchBalance[3] - MonthExecutedValueAux[3];
			IF(PostLaunchBalance[4] <= 0.00) THEN
				PostLaunchBalance[4] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[3] - MonthExecutedValueAux[3];
		
		
			IF(ApliedMonthEf[4] <> -1 AND ApliedMonthHom[4] <> -1 AND ApliedMonthEnd[4] <> -1) THEN
				IF(ApliedMonthEf[4]>0) THEN
					ReclassifiedDifferenceEf[3] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[4]));
					ReclassifiedDifferenceHom[3]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[4]));
					ReclassifiedDifferenceEnd[3]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[4]));
				ELSIF(ApliedMonthHom[4]>0) THEN
					ReclassifiedDifferenceEf[3] = 0;
					ReclassifiedDifferenceHom[3]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[4]));
					ReclassifiedDifferenceEnd[3]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[4]));
				ELSE
					ReclassifiedDifferenceEf[3] = 0;
					ReclassifiedDifferenceHom[3]= 0;
					ReclassifiedDifferenceEnd[3]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[4]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[3] = 0.00;
				ReclassifiedDifferenceHom[3]= 0.00;
				ReclassifiedDifferenceEnd[3]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[4] <> -1 AND ApliedMonthHom[4] <> -1 AND ApliedMonthEnd[4] <> -1) THEN
			IF(ApliedMonthEf[4]>0) THEN
				ReclassifiedBalanceEF[4]  = (EfRate) * (PostLaunchBalance[4]) * (1.00/ (ApliedMonthEf[4]));
				ReclassifiedBalanceHom[4] = (HomRate)* (PostLaunchBalance[4]) * (1.00/(ApliedMonthHom[4]));
				ReclassifiedBalanceEnd[4] = (GoRate) * (PostLaunchBalance[4]) * (1.00/(ApliedMonthEnd[4]));
			ELSIF(ApliedMonthHom[4]>0) THEN
				ReclassifiedBalanceEF[4]  = 0;
				ReclassifiedBalanceHom[4] = (HomGoReclassRate) * (PostLaunchBalance[4]) * (1.00/(ApliedMonthHom[4]));
				ReclassifiedBalanceEnd[4] = (GoEndReclassRate) * (PostLaunchBalance[4]) * (1.00/(ApliedMonthEnd[4]));
			ELSIF(ApliedMonthEnd[4]>0) THEN
				ReclassifiedBalanceEF[4]  = 0;
				ReclassifiedBalanceHom[4] = 0;
				ReclassifiedBalanceEnd[4] = (100.00/100.00) * (PostLaunchBalance[4]) * (1.00/(ApliedMonthEnd[4]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[4]  = BaseValueEf;
			ReclassifiedBalanceHom[4] = BaseValueHom;
			ReclassifiedBalanceEnd[4] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 3 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[3] > CorrectionValue*MonthExpectedValueAux[3] OR PostLaunchBalance[4] = 0) THEN
				NeedToReclassifyBalance[4] = 'Sim';
			ELSE
				NeedToReclassifyBalance[4] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[4] = 'Não';
		END IF;
		
		IF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[4]  = ReclassifiedBalanceEF[4];
			MensalValueHom[4] = ReclassifiedBalanceHom[4];
			MensalValueEnd[4] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[4]  = ReclassifiedBalanceEF[3];
			MensalValueHom[4] = ReclassifiedBalanceHom[3];
			MensalValueEnd[4] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[4]  = ReclassifiedBalanceEF[2];
			MensalValueHom[4] = ReclassifiedBalanceHom[2];
			MensalValueEnd[4] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[4]  = ReclassifiedBalanceEF[1];
			MensalValueHom[4] = ReclassifiedBalanceHom[1];
			MensalValueEnd[4] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[4]  = BaseValueEf;
			MensalValueHom[4] = BaseValueHom;
			MensalValueEnd[4] = BaseValueEnd;
		END IF;
		
		
		IF(MonthStart <= 4 AND 4 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 4 AND 4 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[4];
			END IF;
			
			IF(MonthEfToHom <= 4 AND 4 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[4];
			END IF;
			
			IF(MonthHomToGo <= 4 AND 4 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[4];
			END IF;
			
			
			IF(NeedToReclassifyBalance[4] = 'Não') THEN
				IF(MonthStart <= 4 AND 4 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
				END IF;
				
				IF(MonthEfToHom <= 4 AND 4 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
				END IF;
				
				IF(MonthHomToGo <= 4 AND 4 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
				END IF;
				
				IF(NeedToReclassifyBalance[3] = 'Não') THEN
					IF(MonthStart <= 4 AND 4 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
					END IF;
					
					IF(MonthEfToHom <= 4 AND 4 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
					END IF;
					
					IF(MonthHomToGo <= 4 AND 4 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
					END IF;
					
					
					IF(NeedToReclassifyBalance[2] = 'Não') THEN
						IF(MonthStart <= 4 AND 4 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
						END IF;
						
						IF(MonthEfToHom <= 4 AND 4 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
						END IF;
					
						IF(MonthHomToGo <= 4 AND 4 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
						END IF;
					END IF;
				END IF;
			END IF;
			
			MonthExpectedValueAux[4] = NumberAux;

			UPDATE ForecastProcess SET PrevisionApril = MonthExpectedValueAux[4] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionApril = 0 WHERE ProjectId = Project;
		END IF;
		
		/* ********************************************************************************************************************************************************************** */
		/* MAIO */
		IF(MonthStart <= 5 AND 5 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedMay = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[4] <> -1 AND ApliedMonthHom[4] <> -1 AND ApliedMonthEnd[4] <> -1) THEN
				IF(ApliedMonthEf[4]>=2) THEN
					ApliedMonthEf[5] = ApliedMonthEf[4]-1;
					ApliedMonthHom[5]= ApliedMonthHom[4];
					ApliedMonthEnd[5]= ApliedMonthEnd[4];
					
				ELSIF(ApliedMonthHom[4]>=2) THEN
					ApliedMonthEf[5] = 0;
					ApliedMonthHom[5]= ApliedMonthHom[4]-1;
					ApliedMonthEnd[5]= ApliedMonthEnd[4];
				
				ELSIF(ApliedMonthEnd[4]>=2) THEN
					ApliedMonthEf[5] = 0;
					ApliedMonthHom[5]= 0;
					ApliedMonthEnd[5]= ApliedMonthEnd[4]-1;
				
				ELSE
					ApliedMonthEf[5] = 0;
					ApliedMonthHom[5]= 0;
					ApliedMonthEnd[5]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[5]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[5] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[5] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedMay = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[5]  = -1;
			ApliedMonthHom[5] = -1;
			ApliedMonthEnd[5] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 4 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[4] = 0.00;
			ReclassifiedDifferenceHom[4]= 0.00;
			ReclassifiedDifferenceEnd[4]= 0.00;
			
			PostLaunchBalance[5] = PostLaunchBalance[4];

			MonthExecutedValueAux[4] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 4 AND ProjectId = Project;
			
			MonthExecutedValueAux[4] = NumberAux;
			
			PostLaunchBalance[5] = PostLaunchBalance[4] - MonthExecutedValueAux[4];
			IF(PostLaunchBalance[5] <= 0.00) THEN
				PostLaunchBalance[5] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[4] - MonthExecutedValueAux[4];
		
		
			IF(ApliedMonthEf[5] <> -1 AND ApliedMonthHom[5] <> -1 AND ApliedMonthEnd[5] <> -1) THEN
				IF(ApliedMonthEf[5]>0) THEN
					ReclassifiedDifferenceEf[4] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[5]));
					ReclassifiedDifferenceHom[4]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[5]));
					ReclassifiedDifferenceEnd[4]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[5]));
				ELSIF(ApliedMonthHom[5]>0) THEN
					ReclassifiedDifferenceEf[4] = 0;
					ReclassifiedDifferenceHom[4]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[5]));
					ReclassifiedDifferenceEnd[4]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[5]));
				ELSE
					ReclassifiedDifferenceEf[4] = 0;
					ReclassifiedDifferenceHom[4]= 0;
					ReclassifiedDifferenceEnd[4]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[5]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[4] = 0.00;
				ReclassifiedDifferenceHom[4]= 0.00;
				ReclassifiedDifferenceEnd[4]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[5] <> -1 AND ApliedMonthHom[5] <> -1 AND ApliedMonthEnd[5] <> -1) THEN
			IF(ApliedMonthEf[5]>0) THEN
				ReclassifiedBalanceEF[5]  = (EfRate) * (PostLaunchBalance[5]) * (1.00/ (ApliedMonthEf[5]));
				ReclassifiedBalanceHom[5] = (HomRate)* (PostLaunchBalance[5]) * (1.00/(ApliedMonthHom[5]));
				ReclassifiedBalanceEnd[5] = (GoRate) * (PostLaunchBalance[5]) * (1.00/(ApliedMonthEnd[5]));
			ELSIF(ApliedMonthHom[5]>0) THEN
				ReclassifiedBalanceEF[5]  = 0;
				ReclassifiedBalanceHom[5] = (HomGoReclassRate) * (PostLaunchBalance[5]) * (1.00/(ApliedMonthHom[5]));
				ReclassifiedBalanceEnd[5] = (GoEndReclassRate) * (PostLaunchBalance[5]) * (1.00/(ApliedMonthEnd[5]));
			ELSIF(ApliedMonthEnd[5]>0) THEN
				ReclassifiedBalanceEF[5]  = 0;
				ReclassifiedBalanceHom[5] = 0;
				ReclassifiedBalanceEnd[5] = (100.00/100.00) * (PostLaunchBalance[5]) * (1.00/(ApliedMonthEnd[5]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[5]  = BaseValueEf;
			ReclassifiedBalanceHom[5] = BaseValueHom;
			ReclassifiedBalanceEnd[5] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 4 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[4] > CorrectionValue*MonthExpectedValueAux[4] OR PostLaunchBalance[5] = 0) THEN
				NeedToReclassifyBalance[5] = 'Sim';
			ELSE
				NeedToReclassifyBalance[5] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[5] = 'Não';
		END IF;
		
		
		IF(NeedToReclassifyBalance[5] = 'Sim') THEN
			MensalValueEf[5]  = ReclassifiedBalanceEF[5];
			MensalValueHom[5] = ReclassifiedBalanceHom[5];
			MensalValueEnd[5] = ReclassifiedBalanceEnd[5];
		ELSIF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[5]  = ReclassifiedBalanceEF[4];
			MensalValueHom[5] = ReclassifiedBalanceHom[4];
			MensalValueEnd[5] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[5]  = ReclassifiedBalanceEF[3];
			MensalValueHom[5] = ReclassifiedBalanceHom[3];
			MensalValueEnd[5] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[5]  = ReclassifiedBalanceEF[2];
			MensalValueHom[5] = ReclassifiedBalanceHom[2];
			MensalValueEnd[5] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[5]  = ReclassifiedBalanceEF[1];
			MensalValueHom[5] = ReclassifiedBalanceHom[1];
			MensalValueEnd[5] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[5]  = BaseValueEf;
			MensalValueHom[5] = BaseValueHom;
			MensalValueEnd[5] = BaseValueEnd;
		END IF;
		
		
		IF(MonthStart <= 5 AND 5 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 5 AND 5 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[5];
			END IF;
			
			IF(MonthEfToHom <= 5 AND 5 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[5];
			END IF;
			
			IF(MonthHomToGo <= 5 AND 5 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[5];
			END IF;
			
			
			IF(NeedToReclassifyBalance[5] = 'Não') THEN
				IF(MonthStart <= 5 AND 5 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[4];
				END IF;
				
				IF(MonthEfToHom <= 5 AND 5 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[4];
				END IF;
				
				IF(MonthHomToGo <= 5 AND 5 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[4];
				END IF;
				
				IF(NeedToReclassifyBalance[4] = 'Não') THEN
					IF(MonthStart <= 5 AND 5 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
					END IF;
					
					IF(MonthEfToHom <= 5 AND 5 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
					END IF;
					
					IF(MonthHomToGo <= 5 AND 5 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
					END IF;
					
					IF(NeedToReclassifyBalance[3] = 'Não') THEN
						IF(MonthStart <= 5 AND 5 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
						END IF;
						
						IF(MonthEfToHom <= 5 AND 5 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
						END IF;
						
						IF(MonthHomToGo <= 5 AND 5 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
						END IF;
						
						
						IF(NeedToReclassifyBalance[2] = 'Não') THEN
							IF(MonthStart <= 5 AND 5 <= MonthEfToHom) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
							END IF;
							
							IF(MonthEfToHom <= 5 AND 5 <= MonthHomToGo) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
							END IF;
						
							IF(MonthHomToGo <= 5 AND 5 <= MonthGoToEnd) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
							END IF;
						
						END IF;
					END IF;
				END IF;
			END IF;
			
			MonthExpectedValueAux[5] = NumberAux;

			UPDATE ForecastProcess SET PrevisionMay = MonthExpectedValueAux[5] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionMay = 0 WHERE ProjectId = Project;
		END IF;
		
		/* ********************************************************************************************************************************************************************** */
		/* JUNHO */
		IF(MonthStart <= 6 AND 6 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedJune = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[5] <> -1 AND ApliedMonthHom[5] <> -1 AND ApliedMonthEnd[5] <> -1) THEN
				IF(ApliedMonthEf[5]>=2) THEN
					ApliedMonthEf[6] = ApliedMonthEf[5]-1;
					ApliedMonthHom[6]= ApliedMonthHom[5];
					ApliedMonthEnd[6]= ApliedMonthEnd[5];
					
				ELSIF(ApliedMonthHom[5]>=2) THEN
					ApliedMonthEf[6] = 0;
					ApliedMonthHom[6]= ApliedMonthHom[5]-1;
					ApliedMonthEnd[6]= ApliedMonthEnd[5];
				
				ELSIF(ApliedMonthEnd[5]>=2) THEN
					ApliedMonthEf[6] = 0;
					ApliedMonthHom[6]= 0;
					ApliedMonthEnd[6]= ApliedMonthEnd[5]-1;
				
				ELSE
					ApliedMonthEf[6] = 0;
					ApliedMonthHom[6]= 0;
					ApliedMonthEnd[6]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[6]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[6] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[6] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedJune = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[6]  = -1;
			ApliedMonthHom[6] = -1;
			ApliedMonthEnd[6] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 5 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[5] = 0.00;
			ReclassifiedDifferenceHom[5]= 0.00;
			ReclassifiedDifferenceEnd[5]= 0.00;
			
			PostLaunchBalance[6] = PostLaunchBalance[5];

			MonthExecutedValueAux[5] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 5 AND ProjectId = Project;
			
			MonthExecutedValueAux[5] = NumberAux;
			
			PostLaunchBalance[6] = PostLaunchBalance[5] - MonthExecutedValueAux[5];
			IF(PostLaunchBalance[6] <= 0.00) THEN
				PostLaunchBalance[6] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[5] - MonthExecutedValueAux[5];
		
		
			IF(ApliedMonthEf[6] <> -1 AND ApliedMonthHom[6] <> -1 AND ApliedMonthEnd[6] <> -1) THEN
				IF(ApliedMonthEf[6]>0) THEN
					ReclassifiedDifferenceEf[5] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[6]));
					ReclassifiedDifferenceHom[5]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[6]));
					ReclassifiedDifferenceEnd[5]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[6]));
				ELSIF(ApliedMonthHom[6]>0) THEN
					ReclassifiedDifferenceEf[5] = 0;
					ReclassifiedDifferenceHom[5]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[6]));
					ReclassifiedDifferenceEnd[5]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[6]));
				ELSE
					ReclassifiedDifferenceEf[5] = 0;
					ReclassifiedDifferenceHom[5]= 0;
					ReclassifiedDifferenceEnd[5]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[6]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[5] = 0.00;
				ReclassifiedDifferenceHom[5]= 0.00;
				ReclassifiedDifferenceEnd[5]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[6] <> -1 AND ApliedMonthHom[6] <> -1 AND ApliedMonthEnd[6] <> -1) THEN
			IF(ApliedMonthEf[6]>0) THEN
				ReclassifiedBalanceEF[6]  = (EfRate) * (PostLaunchBalance[6]) * (1.00/ (ApliedMonthEf[6]));
				ReclassifiedBalanceHom[6] = (HomRate)* (PostLaunchBalance[6]) * (1.00/(ApliedMonthHom[6]));
				ReclassifiedBalanceEnd[6] = (GoRate) * (PostLaunchBalance[6]) * (1.00/(ApliedMonthEnd[6]));
			ELSIF(ApliedMonthHom[6]>0) THEN
				ReclassifiedBalanceEF[6]  = 0;
				ReclassifiedBalanceHom[6] = (HomGoReclassRate) * (PostLaunchBalance[6]) * (1.00/(ApliedMonthHom[6]));
				ReclassifiedBalanceEnd[6] = (GoEndReclassRate) * (PostLaunchBalance[6]) * (1.00/(ApliedMonthEnd[6]));
			ELSIF(ApliedMonthEnd[6]>0) THEN
				ReclassifiedBalanceEF[6]  = 0;
				ReclassifiedBalanceHom[6] = 0;
				ReclassifiedBalanceEnd[6] = (100.00/100.00) * (PostLaunchBalance[6]) * (1.00/(ApliedMonthEnd[6]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[6]  = BaseValueEf;
			ReclassifiedBalanceHom[6] = BaseValueHom;
			ReclassifiedBalanceEnd[6] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 5 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[5] > CorrectionValue*MonthExpectedValueAux[5] OR PostLaunchBalance[6] = 0) THEN
				NeedToReclassifyBalance[6] = 'Sim';
			ELSE
				NeedToReclassifyBalance[6] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[6] = 'Não';
		END IF;
		
		
		IF(NeedToReclassifyBalance[6] = 'Sim') THEN
			MensalValueEf[6]  = ReclassifiedBalanceEF[6];
			MensalValueHom[6] = ReclassifiedBalanceHom[6];
			MensalValueEnd[6] = ReclassifiedBalanceEnd[6];
		ELSIF(NeedToReclassifyBalance[5] = 'Sim') THEN
			MensalValueEf[6]  = ReclassifiedBalanceEF[5];
			MensalValueHom[6] = ReclassifiedBalanceHom[5];
			MensalValueEnd[6] = ReclassifiedBalanceEnd[5];
		ELSIF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[6]  = ReclassifiedBalanceEF[4];
			MensalValueHom[6] = ReclassifiedBalanceHom[4];
			MensalValueEnd[6] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[6]  = ReclassifiedBalanceEF[3];
			MensalValueHom[6] = ReclassifiedBalanceHom[3];
			MensalValueEnd[6] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[6]  = ReclassifiedBalanceEF[2];
			MensalValueHom[6] = ReclassifiedBalanceHom[2];
			MensalValueEnd[6] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[6]  = ReclassifiedBalanceEF[1];
			MensalValueHom[6] = ReclassifiedBalanceHom[1];
			MensalValueEnd[6] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[6]  = BaseValueEf;
			MensalValueHom[6] = BaseValueHom;
			MensalValueEnd[6] = BaseValueEnd;
		END IF;
		
		
		IF(MonthStart <= 6 AND 6 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 6 AND 6 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[6];
			END IF;
			
			IF(MonthEfToHom <= 6 AND 6 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[6];
			END IF;
			
			IF(MonthHomToGo <= 6 AND 6 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[6];
			END IF;
			
			IF(NeedToReclassifyBalance[6] = 'Não') THEN
				IF(MonthStart <= 6 AND 6 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[5];
				END IF;
				
				IF(MonthEfToHom <= 6 AND 6 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[5];
				END IF;
				
				IF(MonthHomToGo <= 6 AND 6 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[5];
				END IF;
				
				IF(NeedToReclassifyBalance[5] = 'Não') THEN
					IF(MonthStart <= 6 AND 6 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[4];
					END IF;
					
					IF(MonthEfToHom <= 6 AND 6 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[4];
					END IF;
					
					IF(MonthHomToGo <= 6 AND 6 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[4];
					END IF;
					
					IF(NeedToReclassifyBalance[4] = 'Não') THEN
						IF(MonthStart <= 6 AND 6 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
						END IF;
						
						IF(MonthEfToHom <= 6 AND 6 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
						END IF;
					
						IF(MonthHomToGo <= 6 AND 6 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
						END IF;
						
						IF(NeedToReclassifyBalance[3] = 'Não') THEN
							IF(MonthStart <= 6 AND 6 <= MonthEfToHom) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
							END IF;
							
							IF(MonthEfToHom <= 6 AND 6 <= MonthHomToGo) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
							END IF;
							
							IF(MonthHomToGo <= 6 AND 6 <= MonthGoToEnd) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
							END IF;
							
							
							IF(NeedToReclassifyBalance[2] = 'Não') THEN
								IF(MonthStart <= 6 AND 6 <= MonthEfToHom) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
								END IF;
								
								IF(MonthEfToHom <= 6 AND 6 <= MonthHomToGo) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
								END IF;
								
								IF(MonthHomToGo <= 6 AND 6 <= MonthGoToEnd) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
								END IF;
							
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;	
			
			MonthExpectedValueAux[6] = NumberAux;
			
			UPDATE ForecastProcess SET PrevisionJune = MonthExpectedValueAux[6] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionJune = 0 WHERE ProjectId = Project;
		END IF;
		
		
		/* ********************************************************************************************************************************************************************** */
		/* JULHO */
		IF(MonthStart <= 7 AND 7 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedJuly = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[6] <> -1 AND ApliedMonthHom[6] <> -1 AND ApliedMonthEnd[6] <> -1) THEN
				IF(ApliedMonthEf[6]>=2) THEN
					ApliedMonthEf[7] = ApliedMonthEf[6]-1;
					ApliedMonthHom[7]= ApliedMonthHom[6];
					ApliedMonthEnd[7]= ApliedMonthEnd[6];
					
				ELSIF(ApliedMonthHom[6]>=2) THEN
					ApliedMonthEf[7] = 0;
					ApliedMonthHom[7]= ApliedMonthHom[6]-1;
					ApliedMonthEnd[7]= ApliedMonthEnd[6];
				
				ELSIF(ApliedMonthEnd[6]>=2) THEN
					ApliedMonthEf[7] = 0;
					ApliedMonthHom[7]= 0;
					ApliedMonthEnd[7]= ApliedMonthEnd[6]-1;
				
				ELSE
					ApliedMonthEf[7] = 0;
					ApliedMonthHom[7]= 0;
					ApliedMonthEnd[7]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[7]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[7] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[7] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedJuly = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[7]  = -1;
			ApliedMonthHom[7] = -1;
			ApliedMonthEnd[7] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 6 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[6] = 0.00;
			ReclassifiedDifferenceHom[6]= 0.00;
			ReclassifiedDifferenceEnd[6]= 0.00;
			
			PostLaunchBalance[7] = PostLaunchBalance[6];

			MonthExecutedValueAux[6] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 6 AND ProjectId = Project;
			
			MonthExecutedValueAux[6] = NumberAux;
			
			PostLaunchBalance[7] = PostLaunchBalance[6] - MonthExecutedValueAux[6];
			IF(PostLaunchBalance[7] <= 0.00) THEN
				PostLaunchBalance[7] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[6] - MonthExecutedValueAux[6];
		
		
			IF(ApliedMonthEf[7] <> -1 AND ApliedMonthHom[7] <> -1 AND ApliedMonthEnd[7] <> -1) THEN
				IF(ApliedMonthEf[7]>0) THEN
					ReclassifiedDifferenceEf[6] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[7]));
					ReclassifiedDifferenceHom[6]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[7]));
					ReclassifiedDifferenceEnd[6]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[7]));
				ELSIF(ApliedMonthHom[7]>0) THEN
					ReclassifiedDifferenceEf[6] = 0;
					ReclassifiedDifferenceHom[6]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[7]));
					ReclassifiedDifferenceEnd[6]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[7]));
				ELSE
					ReclassifiedDifferenceEf[6] = 0;
					ReclassifiedDifferenceHom[6]= 0;
					ReclassifiedDifferenceEnd[6]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[7]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[6] = 0.00;
				ReclassifiedDifferenceHom[6]= 0.00;
				ReclassifiedDifferenceEnd[6]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[7] <> -1 AND ApliedMonthHom[7] <> -1 AND ApliedMonthEnd[7] <> -1) THEN
			IF(ApliedMonthEf[7]>0) THEN
				ReclassifiedBalanceEF[7]  = (EfRate) * (PostLaunchBalance[7]) * (1.00/ (ApliedMonthEf[7]));
				ReclassifiedBalanceHom[7] = (HomRate)* (PostLaunchBalance[7]) * (1.00/(ApliedMonthHom[7]));
				ReclassifiedBalanceEnd[7] = (GoRate) * (PostLaunchBalance[7]) * (1.00/(ApliedMonthEnd[7]));
			ELSIF(ApliedMonthHom[7]>0) THEN
				ReclassifiedBalanceEF[7]  = 0;
				ReclassifiedBalanceHom[7] = (HomGoReclassRate) * (PostLaunchBalance[7]) * (1.00/(ApliedMonthHom[7]));
				ReclassifiedBalanceEnd[7] = (GoEndReclassRate) * (PostLaunchBalance[7]) * (1.00/(ApliedMonthEnd[7]));
			ELSIF(ApliedMonthEnd[7]>0) THEN
				ReclassifiedBalanceEF[7]  = 0;
				ReclassifiedBalanceHom[7] = 0;
				ReclassifiedBalanceEnd[7] = (100.00/100.00) * (PostLaunchBalance[7]) * (1.00/(ApliedMonthEnd[7]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[7]  = BaseValueEf;
			ReclassifiedBalanceHom[7] = BaseValueHom;
			ReclassifiedBalanceEnd[7] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 6 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[6] > CorrectionValue*MonthExpectedValueAux[6] OR PostLaunchBalance[7] = 0) THEN
				NeedToReclassifyBalance[7] = 'Sim';
			ELSE
				NeedToReclassifyBalance[7] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[7] = 'Não';
		END IF;
		
		IF(NeedToReclassifyBalance[7] = 'Sim') THEN
			MensalValueEf[7]  = ReclassifiedBalanceEF[7];
			MensalValueHom[7] = ReclassifiedBalanceHom[7];
			MensalValueEnd[7] = ReclassifiedBalanceEnd[7];
		ELSIF(NeedToReclassifyBalance[6] = 'Sim') THEN
			MensalValueEf[7]  = ReclassifiedBalanceEF[6];
			MensalValueHom[7] = ReclassifiedBalanceHom[6];
			MensalValueEnd[7] = ReclassifiedBalanceEnd[6];
		ELSIF(NeedToReclassifyBalance[5] = 'Sim') THEN
			MensalValueEf[7]  = ReclassifiedBalanceEF[5];
			MensalValueHom[7] = ReclassifiedBalanceHom[5];
			MensalValueEnd[7] = ReclassifiedBalanceEnd[5];
		ELSIF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[7]  = ReclassifiedBalanceEF[4];
			MensalValueHom[7] = ReclassifiedBalanceHom[4];
			MensalValueEnd[7] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[7]  = ReclassifiedBalanceEF[3];
			MensalValueHom[7] = ReclassifiedBalanceHom[3];
			MensalValueEnd[7] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[7]  = ReclassifiedBalanceEF[2];
			MensalValueHom[7] = ReclassifiedBalanceHom[2];
			MensalValueEnd[7] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[7]  = ReclassifiedBalanceEF[1];
			MensalValueHom[7] = ReclassifiedBalanceHom[1];
			MensalValueEnd[7] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[7]  = BaseValueEf;
			MensalValueHom[7] = BaseValueHom;
			MensalValueEnd[7] = BaseValueEnd;
		END IF;
		
		
		IF(MonthStart <= 7 AND 7 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 7 AND 7 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[7];
			END IF;
			
			IF(MonthEfToHom <= 7 AND 7 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[7];
			END IF;
			
			IF(MonthHomToGo <= 7 AND 7 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[7];
			END IF;
			
			IF(NeedToReclassifyBalance[7] = 'Não') THEN
				IF(MonthStart <= 7 AND 7 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[6];
				END IF;
				
				IF(MonthEfToHom <= 7 AND 7 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[6];
				END IF;
				
				IF(MonthHomToGo <= 7 AND 7 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[6];
				END IF;
				
				IF(NeedToReclassifyBalance[6] = 'Não') THEN
					IF(MonthStart <= 7 AND 7 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[5];
					END IF;
					
					IF(MonthEfToHom <= 7 AND 7 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[5];
					END IF;
					
					IF(MonthHomToGo <= 7 AND 7 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[5];
					END IF;
					
					IF(NeedToReclassifyBalance[5] = 'Não') THEN
						IF(MonthStart <= 7 AND 7 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[4];
						END IF;
						
						IF(MonthEfToHom <= 7 AND 7 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[4];
						END IF;
						
						IF(MonthHomToGo <= 7 AND 7 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[4];
						END IF;
						
						IF(NeedToReclassifyBalance[4] = 'Não') THEN
							IF(MonthStart <= 7 AND 7 <= MonthEfToHom) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
							END IF;
							
							IF(MonthEfToHom <= 7 AND 7 <= MonthHomToGo) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
							END IF;
						
							IF(MonthHomToGo <= 7 AND 7 <= MonthGoToEnd) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
							END IF;
						
							IF(NeedToReclassifyBalance[3] = 'Não') THEN
								IF(MonthStart <= 7 AND 7 <= MonthEfToHom) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
								END IF;
								
								IF(MonthEfToHom <= 7 AND 7 <= MonthHomToGo) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
								END IF;
								
								IF(MonthHomToGo <= 7 AND 7 <= MonthGoToEnd) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
								END IF;
								
								
								IF(NeedToReclassifyBalance[2] = 'Não') THEN
									IF(MonthStart <= 7 AND 7 <= MonthEfToHom) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
									END IF;
									
									IF(MonthEfToHom <= 7 AND 7 <= MonthHomToGo) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
									END IF;
									
									IF(MonthHomToGo <= 7 AND 7 <= MonthGoToEnd) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
									END IF;
								
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;	
			END IF;
			
			
			MonthExpectedValueAux[7] = NumberAux;
			
			UPDATE ForecastProcess SET PrevisionJuly = MonthExpectedValueAux[7] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionJuly = 0 WHERE ProjectId = Project;
		END IF;
		
		/* ********************************************************************************************************************************************************************** */
		/* AGOSTO */
		IF(MonthStart <= 8 AND 8 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedAugust = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[7] <> -1 AND ApliedMonthHom[7] <> -1 AND ApliedMonthEnd[7] <> -1) THEN
				IF(ApliedMonthEf[7]>=2) THEN
					ApliedMonthEf[8] = ApliedMonthEf[7]-1;
					ApliedMonthHom[8]= ApliedMonthHom[7];
					ApliedMonthEnd[8]= ApliedMonthEnd[7];
					
				ELSIF(ApliedMonthHom[7]>=2) THEN
					ApliedMonthEf[8] = 0;
					ApliedMonthHom[8]= ApliedMonthHom[7]-1;
					ApliedMonthEnd[8]= ApliedMonthEnd[7];
				
				ELSIF(ApliedMonthEnd[7]>=2) THEN
					ApliedMonthEf[8] = 0;
					ApliedMonthHom[8]= 0;
					ApliedMonthEnd[8]= ApliedMonthEnd[7]-1;
				
				ELSE
					ApliedMonthEf[8] = 0;
					ApliedMonthHom[8]= 0;
					ApliedMonthEnd[8]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[8]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[8] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[8] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedAugust = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[8]  = -1;
			ApliedMonthHom[8] = -1;
			ApliedMonthEnd[8] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 7 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[7] = 0.00;
			ReclassifiedDifferenceHom[7]= 0.00;
			ReclassifiedDifferenceEnd[7]= 0.00;
			
			PostLaunchBalance[8] = PostLaunchBalance[7];

			MonthExecutedValueAux[7] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 7 AND ProjectId = Project;
			
			MonthExecutedValueAux[7] = NumberAux;
			
			PostLaunchBalance[8] = PostLaunchBalance[7] - MonthExecutedValueAux[7];
			IF(PostLaunchBalance[8] <= 0.00) THEN
				PostLaunchBalance[8] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[7] - MonthExecutedValueAux[7];
		
		
			IF(ApliedMonthEf[8] <> -1 AND ApliedMonthHom[8] <> -1 AND ApliedMonthEnd[8] <> -1) THEN
				IF(ApliedMonthEf[8]>0) THEN
					ReclassifiedDifferenceEf[7] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[8]));
					ReclassifiedDifferenceHom[7]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[8]));
					ReclassifiedDifferenceEnd[7]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[8]));
				ELSIF(ApliedMonthHom[8]>0) THEN
					ReclassifiedDifferenceEf[7] = 0;
					ReclassifiedDifferenceHom[7]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[8]));
					ReclassifiedDifferenceEnd[7]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[8]));
				ELSE
					ReclassifiedDifferenceEf[7] = 0;
					ReclassifiedDifferenceHom[7]= 0;
					ReclassifiedDifferenceEnd[7]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[8]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[7] = 0.00;
				ReclassifiedDifferenceHom[7]= 0.00;
				ReclassifiedDifferenceEnd[7]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[8] <> -1 AND ApliedMonthHom[8] <> -1 AND ApliedMonthEnd[8] <> -1) THEN
			IF(ApliedMonthEf[8]>0) THEN
				ReclassifiedBalanceEF[8]  = (EfRate) * (PostLaunchBalance[8]) * (1.00/ (ApliedMonthEf[8]));
				ReclassifiedBalanceHom[8] = (HomRate)* (PostLaunchBalance[8]) * (1.00/(ApliedMonthHom[8]));
				ReclassifiedBalanceEnd[8] = (GoRate) * (PostLaunchBalance[8]) * (1.00/(ApliedMonthEnd[8]));
			ELSIF(ApliedMonthHom[8]>0) THEN
				ReclassifiedBalanceEF[8]  = 0;
				ReclassifiedBalanceHom[8] = (HomGoReclassRate) * (PostLaunchBalance[8]) * (1.00/(ApliedMonthHom[8]));
				ReclassifiedBalanceEnd[8] = (GoEndReclassRate) * (PostLaunchBalance[8]) * (1.00/(ApliedMonthEnd[8]));
			ELSIF(ApliedMonthEnd[8]>0) THEN
				ReclassifiedBalanceEF[8]  = 0;
				ReclassifiedBalanceHom[8] = 0;
				ReclassifiedBalanceEnd[8] = (100.00/100.00) * (PostLaunchBalance[8]) * (1.00/(ApliedMonthEnd[8]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[8]  = BaseValueEf;
			ReclassifiedBalanceHom[8] = BaseValueHom;
			ReclassifiedBalanceEnd[8] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 7 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[7] > CorrectionValue*MonthExpectedValueAux[7] OR PostLaunchBalance[8] = 0) THEN
				NeedToReclassifyBalance[8] = 'Sim';
			ELSE
				NeedToReclassifyBalance[8] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[8] = 'Não';
		END IF;
		
		IF(NeedToReclassifyBalance[8] = 'Sim') THEN
			MensalValueEf[8]  = ReclassifiedBalanceEF[8];
			MensalValueHom[8] = ReclassifiedBalanceHom[8];
			MensalValueEnd[8] = ReclassifiedBalanceEnd[8];
		ELSIF(NeedToReclassifyBalance[7] = 'Sim') THEN
			MensalValueEf[8]  = ReclassifiedBalanceEF[7];
			MensalValueHom[8] = ReclassifiedBalanceHom[7];
			MensalValueEnd[8] = ReclassifiedBalanceEnd[7];
		ELSIF(NeedToReclassifyBalance[6] = 'Sim') THEN
			MensalValueEf[8]  = ReclassifiedBalanceEF[6];
			MensalValueHom[8] = ReclassifiedBalanceHom[6];
			MensalValueEnd[8] = ReclassifiedBalanceEnd[6];
		ELSIF(NeedToReclassifyBalance[5] = 'Sim') THEN
			MensalValueEf[8]  = ReclassifiedBalanceEF[5];
			MensalValueHom[8] = ReclassifiedBalanceHom[5];
			MensalValueEnd[8] = ReclassifiedBalanceEnd[5];
		ELSIF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[8]  = ReclassifiedBalanceEF[4];
			MensalValueHom[8] = ReclassifiedBalanceHom[4];
			MensalValueEnd[8] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[8]  = ReclassifiedBalanceEF[3];
			MensalValueHom[8] = ReclassifiedBalanceHom[3];
			MensalValueEnd[8] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[8]  = ReclassifiedBalanceEF[2];
			MensalValueHom[8] = ReclassifiedBalanceHom[2];
			MensalValueEnd[8] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[8]  = ReclassifiedBalanceEF[1];
			MensalValueHom[8] = ReclassifiedBalanceHom[1];
			MensalValueEnd[8] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[8]  = BaseValueEf;
			MensalValueHom[8] = BaseValueHom;
			MensalValueEnd[8] = BaseValueEnd;
		END IF;
		
		
		IF(MonthStart <= 8 AND 8 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 8 AND 8 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[8];
			END IF;
			
			IF(MonthEfToHom <= 8 AND 8 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[8];
			END IF;
			
			IF(MonthHomToGo <= 8 AND 8 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[8];
			END IF;
			
			IF(NeedToReclassifyBalance[8] = 'Não') THEN
				IF(MonthStart <= 8 AND 8 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[7];
				END IF;
				
				IF(MonthEfToHom <= 8 AND 8 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[7];
				END IF;
				
				IF(MonthHomToGo <= 8 AND 8 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[7];
				END IF;
			
				IF(NeedToReclassifyBalance[7] = 'Não') THEN
					IF(MonthStart <= 8 AND 8 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[6];
					END IF;
					
					IF(MonthEfToHom <= 8 AND 8 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[6];
					END IF;
					
					IF(MonthHomToGo <= 8 AND 8 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[6];
					END IF;
					
					IF(NeedToReclassifyBalance[6] = 'Não') THEN
						IF(MonthStart <= 8 AND 8 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[5];
						END IF;
						
						IF(MonthEfToHom <= 8 AND 8 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[5];
						END IF;
						
						IF(MonthHomToGo <= 8 AND 8 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[5];
						END IF;
						
						IF(NeedToReclassifyBalance[5] = 'Não') THEN
							IF(MonthStart <= 8 AND 8 <= MonthEfToHom) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEf[4];
							END IF;
							
							IF(MonthEfToHom <= 8 AND 8 <= MonthHomToGo) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceHom[4];
							END IF;
							
							IF(MonthHomToGo <= 8 AND 8 <= MonthGoToEnd) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEnd[4];
							END IF;
							
							IF(NeedToReclassifyBalance[4] = 'Não') THEN
								IF(MonthStart <= 8 AND 8 <= MonthEfToHom) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
								END IF;
								
								IF(MonthEfToHom <= 8 AND 8 <= MonthHomToGo) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
								END IF;
								
								IF(MonthHomToGo <= 8 AND 8 <= MonthGoToEnd) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
								END IF;
								
								IF(NeedToReclassifyBalance[3] = 'Não') THEN
									IF(MonthStart <= 8 AND 8 <= MonthEfToHom) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
									END IF;
									
									IF(MonthEfToHom <= 8 AND 8 <= MonthHomToGo) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
									END IF;
									
									IF(MonthHomToGo <= 8 AND 8 <= MonthGoToEnd) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
									END IF;
									
									
									IF(NeedToReclassifyBalance[2] = 'Não') THEN
										IF(MonthStart <= 8 AND 8 <= MonthEfToHom) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
										END IF;
										
										IF(MonthEfToHom <= 8 AND 8 <= MonthHomToGo) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
										END IF;
										
										IF(MonthHomToGo <= 8 AND 8 <= MonthGoToEnd) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
										END IF;
									
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;	
				END IF;
			END IF;
			
			MonthExpectedValueAux[8] = NumberAux;
			
			UPDATE ForecastProcess SET PrevisionAugust = MonthExpectedValueAux[8] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionAugust = 0 WHERE ProjectId = Project;
		END IF;
		
		/* ********************************************************************************************************************************************************************** */
		/* SETEMBRO */
		IF(MonthStart <= 9 AND 9 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedSeptember = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[8] <> -1 AND ApliedMonthHom[8] <> -1 AND ApliedMonthEnd[8] <> -1) THEN
				IF(ApliedMonthEf[8]>=2) THEN
					ApliedMonthEf[9] = ApliedMonthEf[8]-1;
					ApliedMonthHom[9]= ApliedMonthHom[8];
					ApliedMonthEnd[9]= ApliedMonthEnd[8];
					
				ELSIF(ApliedMonthHom[8]>=2) THEN
					ApliedMonthEf[9] = 0;
					ApliedMonthHom[9]= ApliedMonthHom[8]-1;
					ApliedMonthEnd[9]= ApliedMonthEnd[8];
				
				ELSIF(ApliedMonthEnd[8]>=2) THEN
					ApliedMonthEf[9] = 0;
					ApliedMonthHom[9]= 0;
					ApliedMonthEnd[9]= ApliedMonthEnd[8]-1;
				
				ELSE
					ApliedMonthEf[9] = 0;
					ApliedMonthHom[9]= 0;
					ApliedMonthEnd[9]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[9]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[9] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[9] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedSeptember = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[9]  = -1;
			ApliedMonthHom[9] = -1;
			ApliedMonthEnd[9] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 8 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[8] = 0.00;
			ReclassifiedDifferenceHom[8]= 0.00;
			ReclassifiedDifferenceEnd[8]= 0.00;
			
			PostLaunchBalance[9] = PostLaunchBalance[8];

			MonthExecutedValueAux[8] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 8 AND ProjectId = Project;
			
			MonthExecutedValueAux[8] = NumberAux;
			
			PostLaunchBalance[9] = PostLaunchBalance[8] - MonthExecutedValueAux[8];
			IF(PostLaunchBalance[9] <= 0.00) THEN
				PostLaunchBalance[9] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[8] - MonthExecutedValueAux[8];
		
		
			IF(ApliedMonthEf[9] <> -1 AND ApliedMonthHom[9] <> -1 AND ApliedMonthEnd[9] <> -1) THEN
				IF(ApliedMonthEf[9]>0) THEN
					ReclassifiedDifferenceEf[8] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[9]));
					ReclassifiedDifferenceHom[8]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[9]));
					ReclassifiedDifferenceEnd[8]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[9]));
				ELSIF(ApliedMonthHom[9]>0) THEN
					ReclassifiedDifferenceEf[8] = 0;
					ReclassifiedDifferenceHom[8]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[9]));
					ReclassifiedDifferenceEnd[8]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[9]));
				ELSE
					ReclassifiedDifferenceEf[8] = 0;
					ReclassifiedDifferenceHom[8]= 0;
					ReclassifiedDifferenceEnd[8]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[9]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[8] = 0.00;
				ReclassifiedDifferenceHom[8]= 0.00;
				ReclassifiedDifferenceEnd[8]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[9] <> -1 AND ApliedMonthHom[9] <> -1 AND ApliedMonthEnd[9] <> -1) THEN
			IF(ApliedMonthEf[9]>0) THEN
				ReclassifiedBalanceEF[9]  = (EfRate) * (PostLaunchBalance[9]) * (1.00/ (ApliedMonthEf[9]));
				ReclassifiedBalanceHom[9] = (HomRate)* (PostLaunchBalance[9]) * (1.00/(ApliedMonthHom[9]));
				ReclassifiedBalanceEnd[9] = (GoRate) * (PostLaunchBalance[9]) * (1.00/(ApliedMonthEnd[9]));
			ELSIF(ApliedMonthHom[9]>0) THEN
				ReclassifiedBalanceEF[9]  = 0;
				ReclassifiedBalanceHom[9] = (HomGoReclassRate) * (PostLaunchBalance[9]) * (1.00/(ApliedMonthHom[9]));
				ReclassifiedBalanceEnd[9] = (GoEndReclassRate) * (PostLaunchBalance[9]) * (1.00/(ApliedMonthEnd[9]));
			ELSIF(ApliedMonthEnd[9]>0) THEN
				ReclassifiedBalanceEF[9]  = 0;
				ReclassifiedBalanceHom[9] = 0;
				ReclassifiedBalanceEnd[9] = (100.00/100.00) * (PostLaunchBalance[9]) * (1.00/(ApliedMonthEnd[9]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[9]  = BaseValueEf;
			ReclassifiedBalanceHom[9] = BaseValueHom;
			ReclassifiedBalanceEnd[9] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 8 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[8]/MonthExpectedValueAux[8] > CorrectionValue OR PostLaunchBalance[9] = 0) THEN
				NeedToReclassifyBalance[9] = 'Sim';
			ELSE
				NeedToReclassifyBalance[9] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[9] = 'Não';
		END IF;
		
		
		IF(NeedToReclassifyBalance[9] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[9];
			MensalValueHom[9] = ReclassifiedBalanceHom[9];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[9];
		ELSIF(NeedToReclassifyBalance[8] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[8];
			MensalValueHom[9] = ReclassifiedBalanceHom[8];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[8];
		ELSIF(NeedToReclassifyBalance[7] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[7];
			MensalValueHom[9] = ReclassifiedBalanceHom[7];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[7];
		ELSIF(NeedToReclassifyBalance[6] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[6];
			MensalValueHom[9] = ReclassifiedBalanceHom[6];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[6];
		ELSIF(NeedToReclassifyBalance[5] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[5];
			MensalValueHom[9] = ReclassifiedBalanceHom[5];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[5];
		ELSIF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[4];
			MensalValueHom[9] = ReclassifiedBalanceHom[4];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[3];
			MensalValueHom[9] = ReclassifiedBalanceHom[3];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[2];
			MensalValueHom[9] = ReclassifiedBalanceHom[2];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[9]  = ReclassifiedBalanceEF[1];
			MensalValueHom[9] = ReclassifiedBalanceHom[1];
			MensalValueEnd[9] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[9]  = BaseValueEf;
			MensalValueHom[9] = BaseValueHom;
			MensalValueEnd[9] = BaseValueEnd;
		END IF;
		
		
		IF(MonthStart <= 9 AND 9 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[9];
			END IF;
			
			IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[9];
			END IF;
			
			IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[9];
			END IF;
			
			
			IF(NeedToReclassifyBalance[9] = 'Não') THEN
				IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[8];
				END IF;
				
				IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[8];
				END IF;
				
				IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[8];
				END IF;
				
				
				IF(NeedToReclassifyBalance[8] = 'Não') THEN
					IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[7];
					END IF;
				
					IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[7];
					END IF;
					
					IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[7];
					END IF;
					
					
					IF(NeedToReclassifyBalance[7] = 'Não') THEN
						IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[6];
						END IF;
						
						IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[6];
						END IF;
						
						IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[6];
						END IF;
						
						IF(NeedToReclassifyBalance[6] = 'Não') THEN
							IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEf[5];
							END IF;
							
							IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceHom[5];
							END IF;
						
							IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEnd[5];
							END IF;
							
							IF(NeedToReclassifyBalance[5] = 'Não') THEN
								IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEf[4];
								END IF;
								
								IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceHom[4];
								END IF;
								
								IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEnd[4];
								END IF;
								
								
								IF(NeedToReclassifyBalance[4] = 'Não') THEN
									IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
									END IF;
									
									IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
									END IF;
									
									IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
									END IF;
									
									
									IF(NeedToReclassifyBalance[3] = 'Não') THEN
										IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
										END IF;
										
										IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
										END IF;
										
										IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
										END IF;
										
										
										IF(NeedToReclassifyBalance[2] = 'Não') THEN
											IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
											END IF;
											
											IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
											END IF;
											
											IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
											END IF;
										
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;	
					END IF;
				END IF;
			END IF;
			
			MonthExpectedValueAux[9] = NumberAux;
			
			UPDATE ForecastProcess SET PrevisionSeptember = MonthExpectedValueAux[9] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionSeptember = 0 WHERE ProjectId = Project;
		END IF;
		
		
		/* ********************************************************************************************************************************************************************** */
		/* OUTUBRO */
		IF(MonthStart <= 10 AND 10 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedOctober = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[9] <> -1 AND ApliedMonthHom[9] <> -1 AND ApliedMonthEnd[9] <> -1) THEN
				IF(ApliedMonthEf[9]>=2) THEN
					ApliedMonthEf[10] = ApliedMonthEf[9]-1;
					ApliedMonthHom[10]= ApliedMonthHom[9];
					ApliedMonthEnd[10]= ApliedMonthEnd[9];
					
				ELSIF(ApliedMonthHom[9]>=2) THEN
					ApliedMonthEf[10] = 0;
					ApliedMonthHom[10]= ApliedMonthHom[9]-1;
					ApliedMonthEnd[10]= ApliedMonthEnd[9];
				
				ELSIF(ApliedMonthEnd[9]>=2) THEN
					ApliedMonthEf[10] = 0;
					ApliedMonthHom[10]= 0;
					ApliedMonthEnd[10]= ApliedMonthEnd[9]-1;
				
				ELSE
					ApliedMonthEf[10] = 0;
					ApliedMonthHom[10]= 0;
					ApliedMonthEnd[10]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[10]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[10] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[10] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedOctober = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[10]  = -1;
			ApliedMonthHom[10] = -1;
			ApliedMonthEnd[10] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 9 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[9] = 0.00;
			ReclassifiedDifferenceHom[9]= 0.00;
			ReclassifiedDifferenceEnd[9]= 0.00;
			
			PostLaunchBalance[10] = PostLaunchBalance[9];

			MonthExecutedValueAux[9] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 9 AND ProjectId = Project;
			
			MonthExecutedValueAux[9] = NumberAux;
			
			PostLaunchBalance[10] = PostLaunchBalance[9] - MonthExecutedValueAux[9];
			IF(PostLaunchBalance[10] <= 0.00) THEN
				PostLaunchBalance[10] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[9] - MonthExecutedValueAux[9];
		
		
			IF(ApliedMonthEf[10] <> -1 AND ApliedMonthHom[10] <> -1 AND ApliedMonthEnd[10] <> -1) THEN
				IF(ApliedMonthEf[10]>0) THEN
					ReclassifiedDifferenceEf[9] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[10]));
					ReclassifiedDifferenceHom[9]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[10]));
					ReclassifiedDifferenceEnd[9]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[10]));
				ELSIF(ApliedMonthHom[10]>0) THEN
					ReclassifiedDifferenceEf[9] = 0;
					ReclassifiedDifferenceHom[9]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[10]));
					ReclassifiedDifferenceEnd[9]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[10]));
				ELSE
					ReclassifiedDifferenceEf[9] = 0;
					ReclassifiedDifferenceHom[9]= 0;
					ReclassifiedDifferenceEnd[9]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[10]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[9] = 0.00;
				ReclassifiedDifferenceHom[9]= 0.00;
				ReclassifiedDifferenceEnd[9]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[10] <> -1 AND ApliedMonthHom[10] <> -1 AND ApliedMonthEnd[10] <> -1) THEN
			IF(ApliedMonthEf[10]>0) THEN
				ReclassifiedBalanceEF[10]  = (EfRate) * (PostLaunchBalance[10]) * (1.00/ (ApliedMonthEf[10]));
				ReclassifiedBalanceHom[10] = (HomRate)* (PostLaunchBalance[10]) * (1.00/(ApliedMonthHom[10]));
				ReclassifiedBalanceEnd[10] = (GoRate) * (PostLaunchBalance[10]) * (1.00/(ApliedMonthEnd[10]));
			ELSIF(ApliedMonthHom[10]>0) THEN
				ReclassifiedBalanceEF[10]  = 0;
				ReclassifiedBalanceHom[10] = (HomGoReclassRate) * (PostLaunchBalance[10]) * (1.00/(ApliedMonthHom[10]));
				ReclassifiedBalanceEnd[10] = (GoEndReclassRate) * (PostLaunchBalance[10]) * (1.00/(ApliedMonthEnd[10]));
			ELSIF(ApliedMonthEnd[10]>0) THEN
				ReclassifiedBalanceEF[10]  = 0;
				ReclassifiedBalanceHom[10] = 0;
				ReclassifiedBalanceEnd[10] = (100.00/100.00) * (PostLaunchBalance[10]) * (1.00/(ApliedMonthEnd[10]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[10]  = BaseValueEf;
			ReclassifiedBalanceHom[10] = BaseValueHom;
			ReclassifiedBalanceEnd[10] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 9 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[9] > CorrectionValue*MonthExpectedValueAux[9] OR PostLaunchBalance[10] = 0) THEN
				NeedToReclassifyBalance[10] = 'Sim';
			ELSE
				NeedToReclassifyBalance[10] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[10] = 'Não';
		END IF;
		
		
		IF(NeedToReclassifyBalance[10] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[10];
			MensalValueHom[10] = ReclassifiedBalanceHom[10];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[10];
		ELSIF(NeedToReclassifyBalance[9] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[9];
			MensalValueHom[10] = ReclassifiedBalanceHom[9];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[9];
		ELSIF(NeedToReclassifyBalance[8] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[8];
			MensalValueHom[10] = ReclassifiedBalanceHom[8];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[8];
		ELSIF(NeedToReclassifyBalance[7] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[7];
			MensalValueHom[10] = ReclassifiedBalanceHom[7];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[7];
		ELSIF(NeedToReclassifyBalance[6] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[6];
			MensalValueHom[10] = ReclassifiedBalanceHom[6];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[6];
		ELSIF(NeedToReclassifyBalance[5] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[5];
			MensalValueHom[10] = ReclassifiedBalanceHom[5];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[5];
		ELSIF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[4];
			MensalValueHom[10] = ReclassifiedBalanceHom[4];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[3];
			MensalValueHom[10] = ReclassifiedBalanceHom[3];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[2];
			MensalValueHom[10] = ReclassifiedBalanceHom[2];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[10]  = ReclassifiedBalanceEF[1];
			MensalValueHom[10] = ReclassifiedBalanceHom[1];
			MensalValueEnd[10] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[10]  = BaseValueEf;
			MensalValueHom[10] = BaseValueHom;
			MensalValueEnd[10] = BaseValueEnd;
		END IF;
		
		
		IF(MonthStart <= 10 AND 10 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[10];
			END IF;
			
			IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[10];
			END IF;
			
			IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[10];
			END IF;
			
			IF(NeedToReclassifyBalance[10] = 'Não') THEN
				IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[9];
				END IF;
				
				IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[9];
				END IF;
				
				IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[9];
				END IF;
			
			
				IF(NeedToReclassifyBalance[9] = 'Não') THEN
					IF(MonthStart <= 9 AND 9 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[8];
					END IF;
					
					IF(MonthEfToHom <= 9 AND 9 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[8];
					END IF;
					
					IF(MonthHomToGo <= 9 AND 9 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[8];
					END IF;
					
					
					IF(NeedToReclassifyBalance[8] = 'Não') THEN
						IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[7];
						END IF;
						
						IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[7];
						END IF;
						
						IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[7];
						END IF;
						
						
						IF(NeedToReclassifyBalance[7] = 'Não') THEN
							IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEf[6];
							END IF;
							
							IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceHom[6];
							END IF;
							
							IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEnd[6];
							END IF;
							
							
							IF(NeedToReclassifyBalance[6] = 'Não') THEN
								IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEf[5];
								END IF;
								
								IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceHom[5];
								END IF;
								
								IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEnd[5];
								END IF;
								
								
								IF(NeedToReclassifyBalance[5] = 'Não') THEN
									IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEf[4];
									END IF;
									
									IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceHom[4];
									END IF;
									
									IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEnd[4];
									END IF;
									
									
									IF(NeedToReclassifyBalance[4] = 'Não') THEN
										IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
										END IF;
										
										IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
										END IF;
										
										IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
										END IF;
										
										
										IF(NeedToReclassifyBalance[3] = 'Não') THEN
											IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
											END IF;
											
											IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
											END IF;
											
											IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
											END IF;
											
											
											IF(NeedToReclassifyBalance[2] = 'Não') THEN
												IF(MonthStart <= 10 AND 10 <= MonthEfToHom) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
												END IF;
												
												IF(MonthEfToHom <= 10 AND 10 <= MonthHomToGo) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
												END IF;
												
												IF(MonthHomToGo <= 10 AND 10 <= MonthGoToEnd) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
												END IF;
											
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;	
						END IF;
					END IF;
				END IF;
			END IF;
			
			MonthExpectedValueAux[10] = NumberAux;
			
			UPDATE ForecastProcess SET PrevisionOctober = MonthExpectedValueAux[10] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionOctober = 0 WHERE ProjectId = Project;
		END IF;
		
		
		/* ********************************************************************************************************************************************************************** */
		/* NOVEMBRO */
		IF(MonthStart <= 11 AND 11 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedNovember = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[10] <> -1 AND ApliedMonthHom[10] <> -1 AND ApliedMonthEnd[10] <> -1) THEN
				IF(ApliedMonthEf[10]>=2) THEN
					ApliedMonthEf[11] = ApliedMonthEf[10]-1;
					ApliedMonthHom[11]= ApliedMonthHom[10];
					ApliedMonthEnd[11]= ApliedMonthEnd[10];
					
				ELSIF(ApliedMonthHom[10]>=2) THEN
					ApliedMonthEf[11] = 0;
					ApliedMonthHom[11]= ApliedMonthHom[10]-1;
					ApliedMonthEnd[11]= ApliedMonthEnd[10];
				
				ELSIF(ApliedMonthEnd[10]>=2) THEN
					ApliedMonthEf[11] = 0;
					ApliedMonthHom[11]= 0;
					ApliedMonthEnd[11]= ApliedMonthEnd[10]-1;
				
				ELSE
					ApliedMonthEf[11] = 0;
					ApliedMonthHom[11]= 0;
					ApliedMonthEnd[11]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[11]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[11] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[11] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedNovember = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[11]  = -1;
			ApliedMonthHom[11] = -1;
			ApliedMonthEnd[11] = -1;
		END IF;
		
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 10 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[10] = 0.00;
			ReclassifiedDifferenceHom[10]= 0.00;
			ReclassifiedDifferenceEnd[10]= 0.00;
			
			PostLaunchBalance[11] = PostLaunchBalance[10];

			MonthExecutedValueAux[10] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 10 AND ProjectId = Project;
			
			MonthExecutedValueAux[10] = NumberAux;
			
			PostLaunchBalance[11] = PostLaunchBalance[10] - MonthExecutedValueAux[10];
			IF(PostLaunchBalance[11] <= 0.00) THEN
				PostLaunchBalance[11] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[10] - MonthExecutedValueAux[10];
		
		
			IF(ApliedMonthEf[11] <> -1 AND ApliedMonthHom[11] <> -1 AND ApliedMonthEnd[11] <> -1) THEN
				IF(ApliedMonthEf[11]>0) THEN
					ReclassifiedDifferenceEf[10] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[11]));
					ReclassifiedDifferenceHom[10]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[11]));
					ReclassifiedDifferenceEnd[10]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[11]));
				ELSIF(ApliedMonthHom[11]>0) THEN
					ReclassifiedDifferenceEf[10] = 0;
					ReclassifiedDifferenceHom[10]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[11]));
					ReclassifiedDifferenceEnd[10]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[11]));
				ELSE
					ReclassifiedDifferenceEf[10] = 0;
					ReclassifiedDifferenceHom[10]= 0;
					ReclassifiedDifferenceEnd[10]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[11]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[10] = 0.00;
				ReclassifiedDifferenceHom[10]= 0.00;
				ReclassifiedDifferenceEnd[10]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[11] <> -1 AND ApliedMonthHom[11] <> -1 AND ApliedMonthEnd[11] <> -1) THEN
			IF(ApliedMonthEf[11]>0) THEN
				ReclassifiedBalanceEF[11]  = (EfRate) * (PostLaunchBalance[11]) * (1.00/ (ApliedMonthEf[11]));
				ReclassifiedBalanceHom[11] = (HomRate)* (PostLaunchBalance[11]) * (1.00/(ApliedMonthHom[11]));
				ReclassifiedBalanceEnd[11] = (GoRate) * (PostLaunchBalance[11]) * (1.00/(ApliedMonthEnd[11]));
			ELSIF(ApliedMonthHom[11]>0) THEN
				ReclassifiedBalanceEF[11]  = 0;
				ReclassifiedBalanceHom[11] = (HomGoReclassRate) * (PostLaunchBalance[11]) * (1.00/(ApliedMonthHom[11]));
				ReclassifiedBalanceEnd[11] = (GoEndReclassRate) * (PostLaunchBalance[11]) * (1.00/(ApliedMonthEnd[11]));
			ELSIF(ApliedMonthEnd[11]>0) THEN
				ReclassifiedBalanceEF[11]  = 0;
				ReclassifiedBalanceHom[11] = 0;
				ReclassifiedBalanceEnd[11] = (100.00/100.00) * (PostLaunchBalance[11]) * (1.00/(ApliedMonthEnd[11]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[11]  = BaseValueEf;
			ReclassifiedBalanceHom[11] = BaseValueHom;
			ReclassifiedBalanceEnd[11] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 10 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[10] > CorrectionValue*MonthExpectedValueAux[10] OR PostLaunchBalance[11] = 0) THEN
				NeedToReclassifyBalance[11] = 'Sim';
			ELSE
				NeedToReclassifyBalance[11] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[11] = 'Não';
		END IF;
		
		IF(NeedToReclassifyBalance[11] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[11];
			MensalValueHom[11] = ReclassifiedBalanceHom[11];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[11];
		ELSIF(NeedToReclassifyBalance[10] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[10];
			MensalValueHom[11] = ReclassifiedBalanceHom[10];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[10];
		ELSIF(NeedToReclassifyBalance[9] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[9];
			MensalValueHom[11] = ReclassifiedBalanceHom[9];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[9];
		ELSIF(NeedToReclassifyBalance[8] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[8];
			MensalValueHom[11] = ReclassifiedBalanceHom[8];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[8];
		ELSIF(NeedToReclassifyBalance[7] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[7];
			MensalValueHom[11] = ReclassifiedBalanceHom[7];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[7];
		ELSIF(NeedToReclassifyBalance[6] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[6];
			MensalValueHom[11] = ReclassifiedBalanceHom[6];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[6];
		ELSIF(NeedToReclassifyBalance[5] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[5];
			MensalValueHom[11] = ReclassifiedBalanceHom[5];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[5];
		ELSIF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[4];
			MensalValueHom[11] = ReclassifiedBalanceHom[4];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[3];
			MensalValueHom[11] = ReclassifiedBalanceHom[3];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[2];
			MensalValueHom[11] = ReclassifiedBalanceHom[2];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[11]  = ReclassifiedBalanceEF[1];
			MensalValueHom[11] = ReclassifiedBalanceHom[1];
			MensalValueEnd[11] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[11]  = BaseValueEf;
			MensalValueHom[11] = BaseValueHom;
			MensalValueEnd[11] = BaseValueEnd;
		END IF;
		
		
		
		IF(MonthStart <= 11 AND 11 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[11];
			END IF;
			
			IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[11];
			END IF;
			
			IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[11];
			END IF;
			
			
			IF(NeedToReclassifyBalance[11] = 'Não') THEN
				IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[10];
				END IF;
				
				IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[10];
				END IF;
				
				IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[9];
				END IF;
				
			
				IF(NeedToReclassifyBalance[10] = 'Não') THEN
					IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[9];
					END IF;
					
					IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[9];
					END IF;
					
					IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[9];
					END IF;
					
					
					IF(NeedToReclassifyBalance[9] = 'Não') THEN
						IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[8];
						END IF;
						
						IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[8];
						END IF;
						
						IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[8];
						END IF;
						
						
						IF(NeedToReclassifyBalance[8] = 'Não') THEN
							IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEf[7];
							END IF;
							
							IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceHom[7];
							END IF;
							
							IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEnd[7];
							END IF;
							
							
							IF(NeedToReclassifyBalance[7] = 'Não') THEN
								IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEf[6];
								END IF;
								
								IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceHom[6];
								END IF;
								
								IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEnd[6];
								END IF;
								
								
								IF(NeedToReclassifyBalance[6] = 'Não') THEN
									IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEf[5];
									END IF;
									
									IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceHom[5];
									END IF;
									
									IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEnd[5];
									END IF;
								
								
									IF(NeedToReclassifyBalance[5] = 'Não') THEN
										IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEf[4];
										END IF;
										
										IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceHom[4];
										END IF;
										
										IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEnd[4];
										END IF;
										
										
										IF(NeedToReclassifyBalance[4] = 'Não') THEN
											IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
											END IF;
											
											IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
											END IF;
											
											IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
											END IF;
											
											
											IF(NeedToReclassifyBalance[3] = 'Não') THEN
												IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
												END IF;
												
												IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
												END IF;
												
												IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
												END IF;
												
												
												IF(NeedToReclassifyBalance[2] = 'Não') THEN
													IF(MonthStart <= 11 AND 11 <= MonthEfToHom) THEN
														NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
													END IF;
													
													IF(MonthEfToHom <= 11 AND 11 <= MonthHomToGo) THEN
														NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
													END IF;
													
													IF(MonthHomToGo <= 11 AND 11 <= MonthGoToEnd) THEN
														NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
													END IF;
												
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;	
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
			
			MonthExpectedValueAux[11] = NumberAux;
			
			UPDATE ForecastProcess SET PrevisionNovember = MonthExpectedValueAux[11] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionNovember = 0 WHERE ProjectId = Project;
		END IF;
		
		
		/* ********************************************************************************************************************************************************************** */
		/* DEZEMBRO */
		IF(MonthStart <= 12 AND 12 <= MonthGoToEnd) THEN
			UPDATE ForecastProcess SET ApliedDecember = TRUE WHERE ProjectID = Project;
			
			IF(ApliedMonthEf[11] <> -1 AND ApliedMonthHom[11] <> -1 AND ApliedMonthEnd[11] <> -1) THEN
				IF(ApliedMonthEf[11]>=2) THEN
					ApliedMonthEf[12] = ApliedMonthEf[11]-1;
					ApliedMonthHom[12]= ApliedMonthHom[11];
					ApliedMonthEnd[12]= ApliedMonthEnd[11];
					
				ELSIF(ApliedMonthHom[11]>=2) THEN
					ApliedMonthEf[12] = 0;
					ApliedMonthHom[12]= ApliedMonthHom[11]-1;
					ApliedMonthEnd[12]= ApliedMonthEnd[11];
				
				ELSIF(ApliedMonthEnd[11]>=2) THEN
					ApliedMonthEf[12] = 0;
					ApliedMonthHom[12]= 0;
					ApliedMonthEnd[12]= ApliedMonthEnd[12]-1;
				
				ELSE
					ApliedMonthEf[12] = 0;
					ApliedMonthHom[12]= 0;
					ApliedMonthEnd[12]= 0;
				
				END IF;
			ELSE
				ApliedMonthEf[12]  = MonthEfToHom - MonthStart + 1;
				ApliedMonthHom[12] = MonthHomToGo - MonthEfToHom + 1;
				ApliedMonthEnd[12] = MonthGoToEnd - MonthHomToGo + 1;
			END IF;
			
		ELSE
			UPDATE ForecastProcess SET ApliedDecember = FALSE WHERE ProjectID = Project;
			
			ApliedMonthEf[12]  = -1;
			ApliedMonthHom[12] = -1;
			ApliedMonthEnd[12] = -1;
		END IF;
		
		
		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 11 AND ProjectId = Project;
		
		IF(NumberAux = 0) THEN
			ReclassifiedDifferenceEf[11] = 0.00;
			ReclassifiedDifferenceHom[11]= 0.00;
			ReclassifiedDifferenceEnd[11]= 0.00;
			
			PostLaunchBalance[12] = PostLaunchBalance[11];

			MonthExecutedValueAux[11] = 0;
			
		ELSIF(NumberAux >= 1) THEN
			SELECT SUM(CostValue) INTO NumberAux
			FROM FinancialLaunch
			WHERE EXTRACT(MONTH FROM LaunchMonth) = 11 AND ProjectId = Project;
			
			MonthExecutedValueAux[11] = NumberAux;
			
			PostLaunchBalance[12] = PostLaunchBalance[11] - MonthExecutedValueAux[11];
			IF(PostLaunchBalance[12] <= 0.00) THEN
				PostLaunchBalance[12] = 0.00;
			END IF;
			
			NumberAux = MonthExpectedValueAux[12] - MonthExecutedValueAux[12];
		
		
			IF(ApliedMonthEf[12] <> -1 AND ApliedMonthHom[12] <> -1 AND ApliedMonthEnd[12] <> -1) THEN
				IF(ApliedMonthEf[12]>0) THEN
					ReclassifiedDifferenceEf[11] = (EfRate) * (NumberAux) * (1.00/(ApliedMonthEf[12]));
					ReclassifiedDifferenceHom[11]= (HomRate)* (NumberAux) * (1.00/(ApliedMonthHom[12]));
					ReclassifiedDifferenceEnd[11]= (GoRate) * (NumberAux) * (1.00/(ApliedMonthEnd[12]));
				ELSIF(ApliedMonthHom[12]>0) THEN
					ReclassifiedDifferenceEf[11] = 0;
					ReclassifiedDifferenceHom[11]= (HomGoReclassRate) * (NumberAux) * (1.00/(ApliedMonthHom[12]));
					ReclassifiedDifferenceEnd[11]= (GoEndReclassRate) * (NumberAux) * (1.00/(ApliedMonthEnd[12]));
				ELSE
					ReclassifiedDifferenceEf[11] = 0;
					ReclassifiedDifferenceHom[11]= 0;
					ReclassifiedDifferenceEnd[11]= (100.00/100.00) * (NumberAux) * (1.00/(ApliedMonthEnd[12]));
				END IF;
			ELSE
				ReclassifiedDifferenceEf[11] = 0.00;
				ReclassifiedDifferenceHom[11]= 0.00;
				ReclassifiedDifferenceEnd[11]= 0.00;
			END IF;
			
		END IF;
		
		
		IF(ApliedMonthEf[12] <> -1 AND ApliedMonthHom[12] <> -1 AND ApliedMonthEnd[12] <> -1) THEN
			IF(ApliedMonthEf[12]>0) THEN
				ReclassifiedBalanceEF[12]  = (EfRate) * (PostLaunchBalance[12]) * (1.00/ (ApliedMonthEf[12]));
				ReclassifiedBalanceHom[12] = (HomRate)* (PostLaunchBalance[12]) * (1.00/(ApliedMonthHom[12]));
				ReclassifiedBalanceEnd[12] = (GoRate) * (PostLaunchBalance[12]) * (1.00/(ApliedMonthEnd[12]));
			ELSIF(ApliedMonthHom[12]>0) THEN
				ReclassifiedBalanceEF[12]  = 0;
				ReclassifiedBalanceHom[12] = (HomGoReclassRate) * (PostLaunchBalance[12]) * (1.00/(ApliedMonthHom[12]));
				ReclassifiedBalanceEnd[12] = (GoEndReclassRate) * (PostLaunchBalance[12]) * (1.00/(ApliedMonthEnd[12]));
			ELSIF(ApliedMonthEnd[12]>0) THEN
				ReclassifiedBalanceEF[12]  = 0;
				ReclassifiedBalanceHom[12] = 0;
				ReclassifiedBalanceEnd[12] = (100.00/100.00) * (PostLaunchBalance[12]) * (1.00/(ApliedMonthEnd[12]));	
			END IF;
			
		ELSE
			ReclassifiedBalanceEF[12]  = BaseValueEf;
			ReclassifiedBalanceHom[12] = BaseValueHom;
			ReclassifiedBalanceEnd[12] = BaseValueEnd;
		END IF;
		

		SELECT COUNT(IdSerial) INTO NumberAux
		FROM FinancialLaunch
		WHERE EXTRACT(MONTH FROM LaunchMonth) = 11 AND ProjectId = Project;
		
		IF(NumberAux>0) THEN
			IF(MonthExecutedValueAux[11] > CorrectionValue*MonthExpectedValueAux[11] OR PostLaunchBalance[12] = 0) THEN
				NeedToReclassifyBalance[12] = 'Sim';
			ELSE
				NeedToReclassifyBalance[12] = 'Não';
			END IF;
		ELSE
			NeedToReclassifyBalance[12] = 'Não';
		END IF;
		
		IF(NeedToReclassifyBalance[12] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[12];
			MensalValueHom[12] = ReclassifiedBalanceHom[12];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[12];
		ELSIF(NeedToReclassifyBalance[11] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[11];
			MensalValueHom[12] = ReclassifiedBalanceHom[11];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[11];
		ELSIF(NeedToReclassifyBalance[10] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[10];
			MensalValueHom[12] = ReclassifiedBalanceHom[10];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[10];
		ELSIF(NeedToReclassifyBalance[9] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[9];
			MensalValueHom[12] = ReclassifiedBalanceHom[9];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[9];
		ELSIF(NeedToReclassifyBalance[8] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[8];
			MensalValueHom[12] = ReclassifiedBalanceHom[8];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[8];
		ELSIF(NeedToReclassifyBalance[7] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[7];
			MensalValueHom[12] = ReclassifiedBalanceHom[7];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[7];
		ELSIF(NeedToReclassifyBalance[6] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[6];
			MensalValueHom[12] = ReclassifiedBalanceHom[6];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[6];
		ELSIF(NeedToReclassifyBalance[5] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[5];
			MensalValueHom[12] = ReclassifiedBalanceHom[5];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[5];
		ELSIF(NeedToReclassifyBalance[4] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[4];
			MensalValueHom[12] = ReclassifiedBalanceHom[4];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[4];
		ELSIF(NeedToReclassifyBalance[3] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[3];
			MensalValueHom[12] = ReclassifiedBalanceHom[3];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[3];
		ELSIF(NeedToReclassifyBalance[2] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[2];
			MensalValueHom[12] = ReclassifiedBalanceHom[2];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[2];
		ELSIF(NeedToReclassifyBalance[1] = 'Sim') THEN
			MensalValueEf[12]  = ReclassifiedBalanceEF[1];
			MensalValueHom[12] = ReclassifiedBalanceHom[1];
			MensalValueEnd[12] = ReclassifiedBalanceEnd[1];
		ELSE
			MensalValueEf[12]  = BaseValueEf;
			MensalValueHom[12] = BaseValueHom;
			MensalValueEnd[12] = BaseValueEnd;
		END IF;
		
		
		
		IF(MonthStart <= 12 AND 12 <= MonthGoToEnd) THEN
			NumberAux = 0;
			
			IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
				NumberAux = MensalValueEf[12];
			END IF;
			
			IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
				NumberAux = NumberAux + MensalValueHom[12];
			END IF;
			
			IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
				NumberAux = NumberAux + MensalValueEnd[12];
			END IF;
			
			
			IF(NeedToReclassifyBalance[12] = 'Não') THEN
				IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEf[11];
				END IF;
				
				IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceHom[11];
				END IF;
				
				IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
					NumberAux = NumberAux + ReclassifiedDifferenceEnd[9];
				END IF;
			
			
				IF(NeedToReclassifyBalance[11] = 'Não') THEN
					IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEf[10];
					END IF;
					
					IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceHom[10];
					END IF;
					
					IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
						NumberAux = NumberAux + ReclassifiedDifferenceEnd[9];
					END IF;
					
					
					IF(NeedToReclassifyBalance[10] = 'Não') THEN
						IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEf[9];
						END IF;
						
						IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceHom[9];
						END IF;
						
						IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
							NumberAux = NumberAux + ReclassifiedDifferenceEnd[9];
						END IF;
						
						
						IF(NeedToReclassifyBalance[9] = 'Não') THEN
							IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEf[8];
							END IF;
							
							IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceHom[8];
							END IF;
							
							IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
								NumberAux = NumberAux + ReclassifiedDifferenceEnd[8];
							END IF;
							
							
							IF(NeedToReclassifyBalance[8] = 'Não') THEN
								IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEf[7];
								END IF;
								
								IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceHom[7];
								END IF;
								
								IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
									NumberAux = NumberAux + ReclassifiedDifferenceEnd[7];
								END IF;
								
								
								IF(NeedToReclassifyBalance[7] = 'Não') THEN
									IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEf[6];
									END IF;
									
									IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceHom[6];
									END IF;
									
									IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
										NumberAux = NumberAux + ReclassifiedDifferenceEnd[6];
									END IF;
									
									
									IF(NeedToReclassifyBalance[6] = 'Não') THEN
										IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEf[5];
										END IF;
										
										IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceHom[5];
										END IF;
										
										IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
											NumberAux = NumberAux + ReclassifiedDifferenceEnd[5];
										END IF;
										
										
										IF(NeedToReclassifyBalance[5] = 'Não') THEN
											IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceEf[4];
											END IF;
											
											IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceHom[4];
											END IF;
											
											IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
												NumberAux = NumberAux + ReclassifiedDifferenceEnd[4];
											END IF;
											
											
											IF(NeedToReclassifyBalance[4] = 'Não') THEN
												IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceEf[3];
												END IF;
												
												IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceHom[3];
												END IF;
												
												IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
													NumberAux = NumberAux + ReclassifiedDifferenceEnd[3];
												END IF;
												
												
												IF(NeedToReclassifyBalance[3] = 'Não') THEN
													IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
														NumberAux = NumberAux + ReclassifiedDifferenceEf[2];
													END IF;
													
													IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
														NumberAux = NumberAux + ReclassifiedDifferenceHom[2];
													END IF;
													
													IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
														NumberAux = NumberAux + ReclassifiedDifferenceEnd[2];
													END IF;
													
													
													IF(NeedToReclassifyBalance[2] = 'Não') THEN
														IF(MonthStart <= 12 AND 12 <= MonthEfToHom) THEN
															NumberAux = NumberAux + ReclassifiedDifferenceEf[1];
														END IF;
														
														IF(MonthEfToHom <= 12 AND 12 <= MonthHomToGo) THEN
															NumberAux = NumberAux + ReclassifiedDifferenceHom[1];
														END IF;
														
														IF(MonthHomToGo <= 12 AND 12 <= MonthGoToEnd) THEN
															NumberAux = NumberAux + ReclassifiedDifferenceEnd[1];
														END IF;
													
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;	
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
			
			MonthExpectedValueAux[12] = NumberAux;
			
			UPDATE ForecastProcess SET PrevisionDecember = MonthExpectedValueAux[12] WHERE ProjectId = Project;
		
		ELSE
			UPDATE ForecastProcess SET PrevisionDecember = 0 WHERE ProjectId = Project;
		END IF;
		
	END;
$$
LANGUAGE 'plpgsql';