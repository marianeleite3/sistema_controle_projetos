CREATE OR REPLACE FUNCTION AddForecastAndDeliveriesToProject() RETURNS TRIGGER AS
$$
	BEGIN
		INSERT INTO ForecastProcess (
		ProjectId,
		ApliedJanuary,		PrevisionJanuary,	ExecutionJanuary,
		ApliedFebruary,		PrevisionFebruary,	ExecutionFebruary,
		ApliedMarch,		PrevisionMarch,		ExecutionMarch,
		ApliedApril,		PrevisionApril,		ExecutionApril,
		ApliedMay,			PrevisionMay,		ExecutionMay,
		ApliedJune,			PrevisionJune,		ExecutionJune,
		ApliedJuly,			PrevisionJuly,		ExecutionJuly,
		ApliedAugust,		PrevisionAugust,	ExecutionAugust,
		ApliedSeptember,	PrevisionSeptember,	ExecutionSeptember,
		ApliedOctober,		PrevisionOctober,	ExecutionOctober,
		ApliedNovember,		PrevisionNovember,	ExecutionNovember,
		ApliedDecember,		PrevisionDecember,	ExecutionDecember
		) VALUES (
		NEW.ProjectCode, 		-- ProjectId/ProjectCode
		FALSE, 0.00, 0.00,		-- Janeiro
		FALSE, 0.00, 0.00,		-- Fevereiro
		FALSE, 0.00, 0.00,		-- Março
		FALSE, 0.00, 0.00,		-- Abril
		FALSE, 0.00, 0.00,		-- Maio
		FALSE, 0.00, 0.00,		-- Junho
		FALSE, 0.00, 0.00,		-- Julho
		FALSE, 0.00, 0.00,		-- Agosto
		FALSE, 0.00, 0.00,		-- Setembro
		FALSE, 0.00, 0.00,		-- Outubro
		FALSE, 0.00, 0.00,		-- Novembro
		FALSE, 0.00, 0.00		-- Dezembro
		);
		
		INSERT INTO Deliveries(ProjectCode) VALUES (NEW.ProjectCode);
		
		RETURN NEW;
	END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER ConsistencyForecastAndDeliveriesToProjeto_INSERT
AFTER INSERT ON Project
FOR EACH ROW EXECUTE FUNCTION AddForecastAndDeliveriesToProject();
