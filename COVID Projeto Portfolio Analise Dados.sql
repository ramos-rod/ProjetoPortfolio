
SELECT * 
FROM ProjetoPortfolio..CovidDeaths
ORDER BY 3,4


-- Selecionar dados a serem usados
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProjetoPortfolio..CovidDeaths
ORDER BY 1, 2

-- Convertendo colunas para tipo de dado "numeric" para operações
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_deaths numeric
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_cases numeric
ALTER TABLE dbo.CovidDeaths ALTER COLUMN population numeric
ALTER TABLE dbo.CovidDeaths ALTER COLUMN new_cases numeric
ALTER TABLE dbo.CovidDeaths ALTER COLUMN new_deaths numeric
ALTER TABLE dbo.CovidVaccinations ALTER COLUMN new_vaccinations numeric

-- Apresenta a probabilidade de morte por Covid num determinado país ao longo do tempo
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ProjetoPortfolio..CovidDeaths
WHERE location like 'Brazil'
ORDER BY date


-- Apresenta a proporção da população que contraiu Covid num determinado país
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionPercentage
FROM ProjetoPortfolio..CovidDeaths
WHERE location = 'Brazil'
ORDER BY InfectionPercentage DESC


-- Observando a proporção de infectados por Covid em relação a população em cada país
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectionPercentage
FROM ProjetoPortfolio..CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC

-- Observando o percentual da população que morreu por Covid em cada país
SELECT location,  MAX((total_deaths/population))*100 as DeathPercentage
FROM ProjetoPortfolio..CovidDeaths
GROUP BY location
ORDER BY DeathPercentage DESC

-- Observando os países com os maiores números absolutos de mortes
SELECT location, MAX(total_deaths) AS DeathCount
FROM ProjetoPortfolio..CovidDeaths
WHERE continent IS NOT NULL -- <-- nas linhas em que 'continent' é NULL, 'location' representa o agrupamento de todo um continente. Removendo NULL, tem-se os valores de cada país.
GROUP BY location
ORDER BY DeathCount DESC

-- Observando as divisões por continente
SELECT location, MAX(total_deaths) AS DeathCount
FROM ProjetoPortfolio..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' -- <-- seguindo a mesma lógica, aqui seleciona-se 'location' onde 'continent' é NULL para que o agrupamento dos valores corretos por continente ocorra de acordo com as particularidades da tabela original.
GROUP BY location
ORDER BY DeathCount DESC

-- Observações globais
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM ProjetoPortfolio..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2



-- tabela CovidVaccinations
-- Observando população total vs vacinações
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaxx.new_vaccinations
, SUM(vaxx.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, 
  deaths.date) AS total_vaccinations -- determinando vacinação total (já presenta na tabela original) manualmente.
FROM ProjetoPortfolio..CovidDeaths deaths
JOIN ProjetoPortfolio..CovidVaccinations vaxx
	ON deaths.location = vaxx.location 
	AND deaths.date = vaxx.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2, 3


-- TABELA TEMPORARIA

DROP TABLE IF EXISTS #PercentualPopVacinada
CREATE TABLE #PercentualPopVacinada
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_vaccinations numeric
)

INSERT INTO #PercentualPopVacinada
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaxx.new_vaccinations
, SUM(vaxx.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, 
  deaths.date) AS total_vaccinations
FROM ProjetoPortfolio..CovidDeaths deaths
JOIN ProjetoPortfolio..CovidVaccinations vaxx
	ON deaths.location = vaxx.location 
	AND deaths.date = vaxx.date
WHERE deaths.continent IS NOT NULL


SELECT *, (total_vaccinations/population)*100 AS percent_vaccinated
FROM #PercentualPopVacinada


-- Criando VIEW para armazenar dados para visualização posterior

CREATE VIEW PercentualPopVacinada as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaxx.new_vaccinations
, SUM(vaxx.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, 
  deaths.date) AS total_vaccinations, (total_vaccinations/population)*100 AS percent_pop_vaccinated
FROM ProjetoPortfolio..CovidDeaths deaths
JOIN ProjetoPortfolio..CovidVaccinations vaxx
	ON deaths.location = vaxx.location 
	AND deaths.date = vaxx.date
WHERE deaths.continent IS NOT NULL


SELECT *
FROM PercentualPopVacinada