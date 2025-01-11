/*******************************************************************************************************************************/
-- Tabela Usuário
CREATE TABLE EndUser
(
	IdSerial		SERIAL			UNIQUE,
	UserCode		VARCHAR(8)		PRIMARY KEY,
	FullName		VARCHAR(50)		NOT NULL,
	NickName		VARCHAR(15),
	Origem			VARCHAR(25),
	Status			BOOLEAN			DEFAULT TRUE,
	HourlyCost		NUMERIC(10, 2)	NOT NULL,
	Responsibility	VARCHAR(30)		NOT NULL,
	SecurityKey		VARCHAR(8)		NOT NULL DEFAULT 'Alterar1'
);

CREATE TABLE HourlyCostHistory
(
	Identifier		SERIAL			PRIMARY KEY,
	UserId			VARCHAR(8)		NOT NULL,
	HourlyCost		DECIMAL(10, 2)	NOT NULL,
	DateBegins		DATE			NOT NULL 		DEFAULT CURRENT_DATE,
	DateEnds		DATE
);

ALTER TABLE HourlyCostHistory ADD FOREIGN KEY (UserID) REFERENCES EndUser(UserCode) ON UPDATE CASCADE ON DELETE CASCADE;

/*******************************************************************************************************************************/
CREATE TYPE DevelopmenteState_options AS ENUM 
(
    'Aguardando aprovação',
    'Aprovado',
    'Programado',
    'Especificação',
    'Aprovação EF',
    'Desenvolvimento',
    'Teste de TI',
    'Homologação',
    'Go-Live',
    'Operação Assistida',
    'Concluído',
    'Paralisado',
    'Cancelado'
);

-- Tabela Projeto.
CREATE TABLE Project
(
	ProjectCode			VARCHAR(12)					PRIMARY KEY,
	Idserial			SERIAL						UNIQUE NOT NULL,
	Title				VARCHAR(100)				NOT NULL,
	DevelopmentStat		DevelopmenteState_options	NOT NULL DEFAULT 'Aguardando aprovação',
	EstimatedCost		NUMERIC(10, 2),
	ApprovedCost		NUMERIC(10, 2),
	TotalAccomplished	NUMERIC(10, 2)				DEFAULT 0.0,
	TotalAvailable		NUMERIC(10, 2),
	Observations		VARCHAR(1000),
	RequestingArea		VARCHAR(75),
	ExpectedStart		DATE,
	DurationExpected	INT
);

/*******************************************************************************************************************************/
-- Tabela UsuárioProjeto
CREATE TABLE UserProject
(
	UserCode			VARCHAR(8) 					NOT NULL,
	ProjectCode			VARCHAR(12) 				NOT NULL,
	
	PRIMARY KEY(UserCode, ProjectCode)
);

ALTER TABLE UserProject ADD CONSTRAINT fk_user FOREIGN KEY (UserCode) REFERENCES EndUser(UserCode);
ALTER TABLE UserProject ADD CONSTRAINT fk_project FOREIGN KEY (ProjectCode) REFERENCES Project(ProjectCode);

/*******************************************************************************************************************************/
-- Tabela Lançamentos
CREATE TABLE FinancialLaunch
(
	IdSerial			SERIAL						PRIMARY KEY,
	LaunchMonth			DATE						NOT NULL,
	UserID				VARCHAR(8),
	ProjectId			VARCHAR(12)					NOT NULL,
	Hours				INT							DEFAULT 0,
	CostValue			NUMERIC(10, 2)
);

ALTER TABLE FinancialLaunch ADD FOREIGN KEY (ProjectId) REFERENCES Project(ProjectCode) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE FinancialLaunch ADD FOREIGN KEY (UserId) REFERENCES EndUser(UserCode) ON UPDATE CASCADE ON DELETE SET NULL;

/*******************************************************************************************************************************/
-- Tabela de Previsão X Execução.
CREATE TABLE ForecastProcess
(
	IDSerial				SERIAL				PRIMARY KEY,
	ProjectId				VARCHAR(12),
	
	ApliedJanuary			BOOLEAN				DEFAULT FALSE,
	PrevisionJanuary		NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionJanuary		NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedFebruary			BOOLEAN				DEFAULT FALSE,
	PrevisionFebruary		NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionFebruary		NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedMarch				BOOLEAN				DEFAULT FALSE,
	PrevisionMarch			NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionMarch			NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedApril				BOOLEAN				DEFAULT FALSE,
	PrevisionApril			NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionApril			NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedMay				BOOLEAN				DEFAULT FALSE,
	PrevisionMay			NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionMay			NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedJune				BOOLEAN				DEFAULT FALSE,
	PrevisionJune			NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionJune			NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedJuly				BOOLEAN				DEFAULT FALSE,
	PrevisionJuly			NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionJuly			NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedAugust			BOOLEAN				DEFAULT FALSE,
	PrevisionAugust			NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionAugust			NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedSeptember			BOOLEAN				DEFAULT FALSE,
	PrevisionSeptember		NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionSeptember		NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedOctober			BOOLEAN				DEFAULT FALSE,
	PrevisionOctober		NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionOctober		NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedNovember			BOOLEAN				DEFAULT FALSE,
	PrevisionNovember		NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionNovember		NUMERIC(10, 2)		DEFAULT 0.00,
	
	ApliedDecember			BOOLEAN				DEFAULT FALSE,
	PrevisionDecember		NUMERIC(10, 2)		DEFAULT 0.00,
	ExecutionDecember		NUMERIC(10, 2)		DEFAULT 0.00
);

ALTER TABLE ForecastProcess ADD FOREIGN KEY (ProjectId) REFERENCES Project(ProjectCode) ON UPDATE CASCADE ON DELETE SET NULL;

/*******************************************************************************************************************************/
-- Tabela Entregas
CREATE TABLE Deliveries
(
    DeliveryId           				SERIAL 				PRIMARY KEY,
    ProjectCode          				VARCHAR(12) 		NOT NULL,
    
	-- Especificação funcional
	SpecFuncPrevisionStart				DATE,
    SpecFuncPrevisionEnd				DATE,
    SpecFuncExecutionStart				DATE,
    SpecFuncExecutionEnd				DATE,
    
	-- Aprovação EF
	ApprovalPrevisionStart				DATE,
    ApprovalPrevisionEnd				DATE,
    ApprovalExecutionStart				DATE,
    ApprovalExecutionEnd				DATE,
    
	-- Desenvolvimento
	DevelopmentPrevisionStart			DATE,
    DevelopmentPrevisionEnd				DATE,
    DevelopmentExecutionStart			DATE,
    DevelopmentExecutionEnd				DATE,
    
	-- Teste de TI
	TestTIPrevisionStart				DATE,
    TestTIPrevisionEnd					DATE,
    TestTIExecutionStart 				DATE,
    TestTIExecutionEnd					DATE,
    
	-- Homologação
	HomologationPrevisionStart			DATE,
    HomologationPrevisionEnd			DATE,
    HomologationExecutionStart			DATE,
    HomologationExecutionEnd			DATE,
	
	-- Go-live
	GoLivePrevisionStart				DATE,
    GoLivePrevisionEnd					DATE,
    GoLiveExecutionStart				DATE,
    GoLiveExecutionEnd					DATE,
    
	-- Operação Assistida
	AssistedOperationPrevisionStart		DATE,
    AssistedOperationPrevisionEnd		DATE,
    AssistedOperationExecutionStart		DATE,
    AssistedOperationExecutionEnd		DATE
);

ALTER TABLE Deliveries ADD CONSTRAINT fk_project_code FOREIGN KEY (ProjectCode) REFERENCES Project(ProjectCode) ON UPDATE CASCADE ON DELETE CASCADE;