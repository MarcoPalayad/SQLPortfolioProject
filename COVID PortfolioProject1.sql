SELECT *
FROM PortfolioProject1..CovidDeaths
ORDER BY 3, 4

--SELECT *
--FROM PortfolioProject1..CovidVaccinations
--ORDER BY 3, 4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths
ORDER BY 1, 2

--Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE location = 'Philippines'
ORDER BY 1, 2

--Total Cases vs Population
--What percentage of population got Covid

SELECT location, date, total_cases, population, (total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject1..CovidDeaths
WHERE location = 'Philippines'
ORDER BY 1, 2

-- Country with highest infection rate vs population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject1..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCounts
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCounts DESC

--Continent with highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCounts
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCounts DESC

--Global Number

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


--Table Join

SELECT*
FROM PortfolioProject1..CovidDeaths AS DEATHS
JOIN PortfolioProject1..CovidVaccinations AS VAC
	ON DEATHS.location = VAC.location
	AND DEATHS.date = VAC.date

--Total Population vs Total Vactinations

SELECT DEATHS.continent, DEATHS.location, DEATHS.date, DEATHS.population, VAC.new_vaccinations, SUM(CAST(VAC.new_vaccinations AS INT)) OVER 
(Partition By DEATHS.location ORDER BY DEATHS.location, DEATHS.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths AS DEATHS
JOIN PortfolioProject1..CovidVaccinations AS VAC
	ON DEATHS.location = VAC.location
	AND DEATHS.date = VAC.date
WHERE DEATHS.continent IS NOT NULL
ORDER BY 2, 3


-- USE CTE

WITH PopVSVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT DEATHS.continent, DEATHS.location, DEATHS.date, DEATHS.population, VAC.new_vaccinations, SUM(CAST(VAC.new_vaccinations AS INT)) OVER 
(Partition By DEATHS.location ORDER BY DEATHS.location, DEATHS.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths AS DEATHS
JOIN PortfolioProject1..CovidVaccinations AS VAC
	ON DEATHS.location = VAC.location
	AND DEATHS.date = VAC.date
WHERE DEATHS.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS VacPercentage
FROM PopVSVac
WHERE location = 'Philippines'


--TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT DEATHS.continent, DEATHS.location, DEATHS.date, DEATHS.population, VAC.new_vaccinations, SUM(CAST(VAC.new_vaccinations AS INT)) OVER 
(Partition By DEATHS.location ORDER BY DEATHS.location, DEATHS.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths AS DEATHS
JOIN PortfolioProject1..CovidVaccinations AS VAC
	ON DEATHS.location = VAC.location
	AND DEATHS.date = VAC.date
WHERE DEATHS.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100 AS VacPercentage
FROM #PercentPopulationVaccinated
WHERE location = 'Philippines'



-- View for Visualization

CREATE VIEW PercentPeopleVaccinated AS
SELECT DEATHS.continent, DEATHS.location, DEATHS.date, DEATHS.population, VAC.new_vaccinations, SUM(CAST(VAC.new_vaccinations AS INT)) OVER 
(Partition By DEATHS.location ORDER BY DEATHS.location, DEATHS.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths AS DEATHS
JOIN PortfolioProject1..CovidVaccinations AS VAC
	ON DEATHS.location = VAC.location
	AND DEATHS.date = VAC.date
WHERE DEATHS.continent IS NOT NULL

SELECT* 
FROM PercentPeopleVaccinated