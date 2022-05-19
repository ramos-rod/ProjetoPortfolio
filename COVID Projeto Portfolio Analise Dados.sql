
SELECT * 
FROM ProjetoPortfolio..CovidDeaths
ORDER BY 3,4


-- Selecionar dados a serem usados
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProjetoPortfolio..CovidDeaths
ORDER BY 1, 2

-- Convertendo colunas para tipo de dado "numeric" para opera��es
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_deaths numeric
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_cases numeric
ALTER TABLE dbo.CovidDeaths ALTER COLUMN population numeric
ALTER TABLE dbo.CovidDeaths ALTER COLUMN new_cases numeric
ALTER TABLE dbo.CovidDeaths ALTER COLUMN new_deaths numeric
ALTER TABLE dbo.CovidVaccinations ALTER COLUMN new_vaccinations numeric

-- Apresenta a probabilidade de morte por Covid num determinado pa�s ao longo do tempo
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ProjetoPortfolio..CovidDeaths
WHERE location like 'Brazil'
ORDER BY date


-- Apresenta a propor��o da popula��o que contraiu Covid num determinado pa�s
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionPercentage
FROM ProjetoPortfolio..CovidDeaths
WHERE location = 'Brazil'
ORDER BY InfectionPercentage DESC


-- Observando a propor��o de infectados por Covid em rela��o a popula��o em cada pa�s
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectionPercentage
FROM ProjetoPortfolio..CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC

-- Observando o percentual da popula��o que morreu por Covid em cada pa�s
SELECT location,  MAX((total_deaths/population))*100 as DeathPercentage
FROM ProjetoPortfolio..CovidDeaths
GROUP BY location
ORDER BY DeathPercentage DESC

-- Observando os pa�ses com os maiores n�meros absolutos de mortes
SELECT location, MAX(total_deaths) AS DeathCount
FROM ProjetoPortfolio..CovidDeaths
WHERE continent IS NOT NULL -- <-- nas linhas em que 'continent' � NULL, 'location' representa o agrupamento de todo um continente. Removendo NULL, tem-se os valores de cada pa�s.
GROUP BY location
ORDER BY DeathCount DESC

-- Observando as divis�es por continente
SELECT location, MAX(total_deaths) AS DeathCount
FROM ProjetoPortfolio..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' -- <-- seguindo a mesma l�gica, aqui seleciona-se 'location' onde 'continent' � NULL para que o agrupamento dos valores corretos por continente ocorra de acordo com as particularidades da tabela original.
GROUP BY location
ORDER BY DeathCount DESC

-- Observa��es globais
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM ProjetoPortfolio..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2



-- tabela CovidVaccinations
-- Observando popula��o total vs vacina��es
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaxx.new_vaccinations
, SUM(vaxx.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, 
  deaths.date) AS total_vaccinations -- determinando vacina��o total (j� presenta na tabela original) manualmente.
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


-- Criando VIEW para armazenar dados para visualiza��o posterior

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