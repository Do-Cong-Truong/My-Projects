--- In this dataset containing two columns, continent and location, we can see that the location column contains both continent and then the column column will be NULL. Therefore, to determine the insights of each country, we will use the 'WHERE continent IS NOT NULL' statement to remove the continents contained in the location column.

-- SELECT DATA THAT WE ARE GOING TO BE USING

SELECT location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Looking at two columns Total Cases vs Total Deaths, when checking the data type of these two columns, it is not a number, so we will convert to Decimal to be able to perform the next analysis.
-- SHOWS LIKELIHOOD OF DYING IF INFECTED WITH COVID IN VIETNAM

SELECT location
	, date
	, total_cases
	, total_deaths
	, (CAST(total_deaths AS DECIMAL) / CAST(total_cases AS DECIMAL))*100 AS Death_Percentage
FROM CovidDeaths
WHERE location = 'Vietnam'
AND continent IS NOT NULL
ORDER BY location, date

-- Looking at Total Cases vs Population
-- SHOWS WHAT PERCENTAGE OF POPULATION GOT COVID

SELECT location
	, date
	, population
	, total_cases
	, (CAST(total_cases AS DECIMAL) / CAST(population AS DECIMAL))*100 AS Percent_Population_Infected
FROM CovidDeaths
WHERE location = 'Vietnam'
ORDER BY location, date

-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT location
	, population
	, MAX(CAST(total_cases AS DECIMAL)) AS Highest_Infection_Count
	, MAX((CAST(total_cases AS DECIMAL) / CAST(population AS DECIMAL)))*100 AS Percent_Population_Infected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC

-- SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT location
	, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

--- Let's break things down by continent

-- SHOWING CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION

SELECT continent
	, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM CovidDeaths
--WHERE location = 'Vietnam'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC

-- GLOBAL NUMBERS

SELECT date
	, SUM(new_deaths) AS total_deaths
	, SUM(new_cases) AS total_cases
	, CASE WHEN SUM(new_cases) = 0
		THEN NULL 
		ELSE SUM(new_deaths)/SUM(new_cases)*100 END AS Death_Percentage_Date
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

SELECT SUM(new_deaths) AS total_deaths
	, SUM(new_cases) AS total_cases
	, SUM(new_deaths)/SUM(new_cases)*100 AS Death_Percentage_Total
FROM CovidDeaths
WHERE continent IS NOT NULL


-- Column new_vaccinations contains large data, so to avoid arithmetic overflow, we will convert column new_vaccinations to BIGINT, then perform a sum of that column to see the total number of COVID cases up to that day.
-- LOOKING AT TOTAL POPULATION VS VACCINATIONS

WITH PopvsVac AS
(
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
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
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date

SELECT *
	, (RollingPeopleVaccinated/population)*100 AS Percent_People_Vaccinated
FROM #PercentPopulationVaccinated

-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated