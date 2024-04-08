SELECT *
FROM PortfolioProject_COVID..CovidDeaths
ORDER BY location, date

--SELECT *
--FROM PortfolioProject_COVID..CovidVaccines
--ORDER BY location, date

-- Select the data to be analyzed
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject_COVID..CovidDeaths
ORDER BY location, date

--Looking at Total Cases against Total Deaths (percentage)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS mortality_rate
FROM PortfolioProject_COVID..CovidDeaths
ORDER BY location, date

--Create View for Cases vs Deaths
CREATE VIEW CasesVsDeaths AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS mortality_rate
FROM PortfolioProject_COVID..CovidDeaths

--Check United States mortality rates
--Shows likelihood of death if COVID is contracted
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS mortality_rate
FROM PortfolioProject_COVID..CovidDeaths
WHERE location like '%states%'
ORDER BY location, date

--Looking at Total Cases vs Population
--Shows percantage of population that has contracted COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 AS infection_rate
FROM PortfolioProject_COVID..CovidDeaths
WHERE location like '%states%'
ORDER BY location, date

--Looking at countries with highest infection_rate
SELECT location, population, MAX(total_cases) AS total_infected, MAX((total_cases/population))*100 AS infection_rate
FROM PortfolioProject_COVID..CovidDeaths
GROUP BY location, population
ORDER BY infection_rate DESC

--Create view for infection_rate per country
CREATE VIEW Infection
	SELECT location, population, MAX(total_cases) AS total_infected, MAX((total_cases/population))*100 AS infection_rate
FROM PortfolioProject_COVID..CovidDeaths
GROUP BY location, population
--Show countries with highest death counts per population
SELECT location, MAX(total_deaths) AS death_count
FROM PortfolioProject_COVID..CovidDeaths
WHERE continent IS NOT null
GROUP BY location
ORDER BY death_count DESC

--Looking at cases by continent
SELECT location, MAX(total_deaths) AS death_count
FROM PortfolioProject_COVID..CovidDeaths
WHERE continent IS null
GROUP BY location
ORDER BY death_count DESC

--Showing continents with highest death_count
SELECT continent, MAX(total_deaths) AS death_count
FROM PortfolioProject_COVID..CovidDeaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY death_count DESC


--Global Summary
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject_COVID..CovidDeaths
WHERE continent IS NOT null
ORDER BY 1, 2

--Global death_percentage by date
SELECT date, SUM(total_cases) AS total_cases, SUM(total_deaths) AS total_deaths, SUM(total_deaths)/SUM(total_cases)*100 AS death_percentage
FROM PortfolioProject_COVID..CovidDeaths
WHERE continent IS NOT null
GROUP BY date
ORDER BY 1, 2

--Joining tables (template for future queries)
SELECT *
FROM PortfolioProject_COVID..CovidDeaths AS dea
JOIN PortfolioProject_COVID..CovidDeaths AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject_COVID..CovidDeaths AS dea
JOIN PortfolioProject_COVID..CovidVaccines AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY dea.location, dea.date

--Calculating Rolling People Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject_COVID..CovidDeaths AS dea
JOIN PortfolioProject_COVID..CovidVaccines AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY dea.location, dea.date

--Use CTE to evaluate total percent of population vaccinated
WITH PopVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
	AS
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject_COVID..CovidDeaths AS dea
JOIN PortfolioProject_COVID..CovidVaccines AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
)
SELECT *, (rolling_people_vaccinated/population)*100 AS percent_vaccinated
FROM PopVac

--Create View for CTE
CREATE VIEW PercentPopulationVaccinated AS
WITH PopVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
	AS
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject_COVID..CovidDeaths AS dea
JOIN PortfolioProject_COVID..CovidVaccines AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
)
SELECT *, (rolling_people_vaccinated/population)*100 AS percent_vaccinated
FROM PopVac