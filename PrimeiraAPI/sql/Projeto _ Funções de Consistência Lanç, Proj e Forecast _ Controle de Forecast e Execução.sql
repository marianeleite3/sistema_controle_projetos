CREATE OR REPLACE FUNCTION ConsistencyFinancialLaunch() RETURNS TRIGGER AS
$$
	DECLARE
		UserHourlyCost				EndUser.HourlyCost%TYPE;
		NumberAux					NUMERIC(10, 2);
	
	BEGIN
		IF(TG_OP != 'DELETE') THEN
			SELECT EndUser.HourlyCost INTO UserHourlyCost FROM EndUser WHERE EndUser.UserCode = NEW.UserId;
			NumberAux = New.Hours * UserHourlyCost;
			
			UPDATE FinancialLaunch SET CostValue = NumberAux WHERE IdSerial = NEW.IdSerial;
			
			IF(TG_OP = 'INSERT') THEN
				-- Para INSERT só temos a chave "NEW":
				SELECT EndUser.HourlyCost INTO UserHourlyCost FROM EndUser WHERE EndUser.UserCode = NEW.UserId;
				NumberAux = NEW.Hours * UserHourlyCost;
				
				CALL DataConsistencyForProjectAndForecast(NEW.ProjectId						  ::VARCHAR(12), 
														  NumberAux							  ::NUMERIC(10, 2),
														  EXTRACT(MONTH FROM NEW.LaunchMonth) ::INT);
				
			ELSIF(TG_OP = 'UPDATE') THEN
				-- Para a chave "NEW"
				SELECT EndUser.HourlyCost INTO UserHourlyCost FROM EndUser WHERE EndUser.UserCode = NEW.UserId;
				NumberAux = NEW.Hours * UserHourlyCost;
				
				CALL DataConsistencyForProjectAndForecast(NEW.ProjectId						  ::VARCHAR(12),
														  NumberAux							  ::NUMERIC(10, 2),
														  EXTRACT(MONTH FROM NEW.LaunchMonth) ::INT);
				
				-- Para a chave "OLD"
				SELECT EndUser.HourlyCost INTO UserHourlyCost FROM EndUser WHERE EndUser.UserCode = OLD.UserId;
				NumberAux = -1.00 * OLD.Hours * UserHourlyCost;
				
				CALL DataConsistencyForProjectAndForecast(OLD.ProjectId						  ::VARCHAR(12),
														  NumberAux							  ::NUMERIC(10, 2),
														  EXTRACT(MONTH FROM OLD.LaunchMonth) ::INT);
			END IF;
			
			RETURN NEW;
		ELSE
			-- Ao Deletar uma chave, não haverá mais uma chave para ser atualizada na tabela FinancialLaunch, logo só reduzimos
			-- o valor da tabela de projetos e forecast.
			SELECT EndUser.HourlyCost INTO UserHourlyCost FROM EndUser WHERE EndUser.UserCode = OLD.UserId;
			NumberAux = -1.00 * OLD.Hours * UserHourlyCost;
			
			CALL DataConsistencyForProjectAndForecast(OLD.ProjectId						  ::VARCHAR(12),
													  NumberAux							  ::NUMERIC(10, 2),
													  EXTRACT(MONTH FROM OLD.LaunchMonth) ::INT);
			
			RETURN OLD;
		END IF;
	END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE PROCEDURE DataConsistencyForProjectAndForecast(ProjectParameter VARCHAR(12), Amount NUMERIC(10, 2), MonthForLaunch INT) AS
$$
	BEGIN
    	-- Atualiza a coluna TotalAccomplished na tabela Projects
    	UPDATE Project SET TotalAccomplished = TotalAccomplished + Amount WHERE ProjectCode = ProjectParameter;
		
    	-- Atualiza a coluna de execução correspondente no ForecastProcess com base no mês do lançamento
    	UPDATE ForecastProcess
    	SET
        	ExecutionJanuary = ExecutionJanuary + (CASE WHEN (MonthForLaunch) = 1 THEN amount ELSE 0 END),
        	ExecutionFebruary = ExecutionFebruary + (CASE WHEN (MonthForLaunch) = 2 THEN amount ELSE 0 END),
        	ExecutionMarch = ExecutionMarch + (CASE WHEN (MonthForLaunch) = 3 THEN amount ELSE 0 END),
        	ExecutionApril = ExecutionApril + (CASE WHEN (MonthForLaunch) = 4 THEN amount ELSE 0 END),
        	ExecutionMay = ExecutionMay + (CASE WHEN (MonthForLaunch) = 5 THEN amount ELSE 0 END),
        	ExecutionJune = ExecutionJune + (CASE WHEN (MonthForLaunch) = 6 THEN amount ELSE 0 END),
        	ExecutionJuly = ExecutionJuly + (CASE WHEN (MonthForLaunch) = 7 THEN amount ELSE 0 END),
        	ExecutionAugust = ExecutionAugust + (CASE WHEN (MonthForLaunch) = 8 THEN amount ELSE 0 END),
        	ExecutionSeptember = ExecutionSeptember + (CASE WHEN (MonthForLaunch) = 9 THEN amount ELSE 0 END),
        	ExecutionOctober = ExecutionOctober + (CASE WHEN (MonthForLaunch) = 10 THEN amount ELSE 0 END),
        	ExecutionNovember = ExecutionNovember + (CASE WHEN (MonthForLaunch) = 11 THEN amount ELSE 0 END),
        	ExecutionDecember = ExecutionDecember + (CASE WHEN (MonthForLaunch) = 12 THEN amount ELSE 0 END)
    	WHERE ProjectId = ProjectParameter;	
	END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER ConsistencyForFinancialLaunch
AFTER INSERT OR UPDATE OR DELETE ON FinancialLaunch
FOR EACH ROW
WHEN (pg_trigger_depth() < 1)
EXECUTE FUNCTION ConsistencyFinancialLaunch();