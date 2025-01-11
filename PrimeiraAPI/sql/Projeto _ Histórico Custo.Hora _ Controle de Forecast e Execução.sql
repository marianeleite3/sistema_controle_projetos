/*************************************************************************************************************************/
/* Inclusão de um novo funcionário */
CREATE OR REPLACE FUNCTION HistoryControlForEndUserHourlyCost_INSERT() RETURNS TRIGGER AS
$$
	DECLARE
		WorkerCode			EndUser.UserCode%TYPE;
		NewHourlyCost		EndUser.HourlyCost%TYPE;
		
	BEGIN
		SELECT UserCode INTO WorkerCode FROM EndUser WHERE UserCode = NEW.UserCode;
		SELECT HourlyCost INTO NewHourlyCost FROM EndUser WHERE UserCode = NEW.UserCode;
		
		INSERT INTO HourlyCostHistory(UserId, HourlyCost)
			VALUES (WorkerCode, NewHourlyCost);
			
		RETURN NEW;
	END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER HistoricalHourlyCostControl_INSERT
AFTER INSERT ON EndUser
FOR EACH ROW EXECUTE FUNCTION HistoryControlForEndUserHourlyCost_Insert();

/*************************************************************************************************************************/
/* Atualização da hora do funcionário */
CREATE OR REPLACE FUNCTION HistoryControlForEndUserHourlyCost_UPDATE() RETURNS TRIGGER AS
$$
	DECLARE
		LastHistoryInstance		HourlyCostHistory.Identifier%TYPE;
	
	BEGIN
		IF( (OLD.status != NEW.Status) AND
		    (OLD.HourlyCost != NEW.HourlyCost)
		   ) THEN
		   
				SELECT HourlyCostHistory.Identifier INTO LastHistoryInstance
				FROM HourlyCostHistory 
				WHERE HourlyCostHistory.UserId = NEW.UserCode AND HourlyCostHistory.DateEnds IS NULL;
				
				IF(OLD.Status != NEW.Status AND NEW.Status = FALSE) THEN
					UPDATE HourlyCostHistory SET HourlyCostHistory.DateEnds = CURRENT_DATE WHERE HourlyCostHistory.Identifier = LastHistoryInstance;
				
				ELSIF (OLD.HourlyCost != NEW.HourlyCost) THEN
					UPDATE HourlyCostHistory SET DateEnds = CURRENT_DATE-1 WHERE HourlyCostHistory.Identifier = LastHistoryInstance;
					
					INSERT INTO HourlyCostHistory(WorkerId, HourlyCost) VALUES (NEW.UserCode, New.HourlyCost);
				
				END IF;
		END IF;
		
		RETURN NEW;
	END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER HistoricalHourlyCostControl_UPDATE
AFTER UPDATE ON EndUser
FOR EACH ROW EXECUTE FUNCTION HistoryControlForEndUserHourlyCost_UPDATE();