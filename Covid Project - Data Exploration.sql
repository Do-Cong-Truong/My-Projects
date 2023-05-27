SELECT *
FROM [Portfolio Project - Covid]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Select Data that we are going to be using

SELECT location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM [Portfolio Project - Covid]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if infected with Covid in VietNam

SELECT location
	, date
	, total_cases
	, total_deaths
	, (CAST(total_deaths AS DECIMAL) / CAST(total_cases AS DECIMAL))*100 AS Death_Percentage
FROM [Portfolio Project - Covid]..CovidDeaths
WHERE location = 'Vietnam'
AND continent IS NOT NULL
ORDER BY location, date

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT location
	, date
	, population
	, total_cases
	, (CAST(total_cases AS DECIMAL) / CAST(population AS DECIMAL))*100 AS Percent_Population_Infected
FROM [Portfolio Project - Covid]..CovidDeaths
WHERE location = 'Vietnam'
ORDER BY location, date

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location
	, population
	, MAX(CAST(total_cases AS INT)) AS Highest_Infection_Count
	, MAX((CAST(total_cases AS DECIMAL) / CAST(population AS DECIMAL)))*100 AS Percent_Population_Infected
FROM [Portfolio Project - Covid]..CovidDeaths
--WHERE location = 'Vietnam'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC

-- Showing Countries with Highest Death Count per Population

SELECT location
	, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM [Portfolio Project - Covid]..CovidDeaths
--WHERE location = 'Vietnam'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

-- Let's break things down by continent

-- Showing continents with the highest death count per population

SELECT continent
	, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM [Portfolio Project - Covid]..CovidDeaths
--WHERE location = 'Vietnam'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC

-- Global Numbers

SELECT date
	, SUM(new_deaths) AS total_deaths
	, SUM(new_cases) AS total_cases
	, CASE WHEN SUM(new_cases) = 0
		THEN NULL 
		ELSE SUM(new_deaths)/SUM(new_cases)*100 END AS Death_Percentage_Date
FROM [Portfolio Project - Covid]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

SELECT SUM(new_deaths) AS total_deaths
	, SUM(new_cases) AS total_cases
	, SUM(new_deaths)/SUM(new_cases)*100 AS Death_Percentage_Total
FROM [Portfolio Project - Covid]..CovidDeaths
WHERE continent IS NOT NULL



-- Looking at Total Population vs Vaccinations

WITH PopvsVac AS
(
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM [Portfolio Project - Covid]..CovidDeaths dea
JOIN [Portfolio Project - Covid]..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *
	, (Rolling_People_Vaccinated/population)*100 AS Percent_People_Vaccinated
FROM PopvsVac
ORDER BY location, date

-- TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
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
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project - Covid]..CovidDeaths dea
JOIN [Portfolio Project - Covid]..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date

SELECT *
	, (RollingPeopleVaccinated/population)*100 AS Percent_People_Vaccinated
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project - Covid]..CovidDeaths dea
JOIN [Portfolio Project - Covid]..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date

SELECT * 
FROM PercentPopulationVaccinated
