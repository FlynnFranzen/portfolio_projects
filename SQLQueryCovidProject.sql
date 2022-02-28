SELECT *
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--SELECT *
--FROM portfolio_project..covid_vaccinations
--ORDER BY 3,4
 

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Total Cases vs Total Deaths
-- The likelihood you will die if you contract Covid in your country (By Percentage)

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM portfolio_project..covid_deaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Total Cases vs The Population
-- What percentage of the population got Covid

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS infection_rate
FROM portfolio_project..covid_deaths
WHERE location LIKE '%states%' AND WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Countries with the highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM portfolio_project..covid_deaths
GROUP BY Location, population
ORDER BY percent_population_infected DESC

-- Countries with the Highest Death Count per Population
-- CAST total_deaths as INTEGER for query to count properly

SELECT Location,MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY total_death_count DESC

-- Statistics broken down by continent
-- Query only pulls from certain countries within each continent .. 
-- i.e. 'North America' only shows deaths from the U.S.

SELECT continent,MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- Here is the fix for this problem
-- Replace 'continent' with 'location'
-- Change 'IS NOT NULL' to 'IS NULL'

SELECT location,MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM portfolio_project..covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

-- GLOBAL NUMBERS - By date
-- Changed data type (varchar255) to Integer with CAST function


SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS global_death_percentage
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- GLOBAL NUMBERS - Overall

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS global_death_percentage
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2

-- Here we will use JOIN to join both tables together ON location and date

SELECT * 
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date;

-- Looking at Total Population vs Vaccinations


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3 

-- Creating a CTE to find the Percentage of Populations that are Vaccinated

WITH pop_vs_vax (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
) 
SELECT *, (rolling_people_vaccinated/population)*100 AS percent_population_vaxxed
FROM pop_vs_vax

-- CREATING A TEMP TABLE

CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(225),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated/population)*100 AS percent_population_vaxxed
FROM #percent_population_vaccinated

-- Making changes to the Temp Table
-- Adding 'DROP TABLE IF EXISTS #temp_table_name' 

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(225),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3,

SELECT *, (rolling_people_vaccinated/population)*100 AS percent_population_vaxxed
FROM #percent_population_vaccinated

-- Creating view to store data for later visualiazations 

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- Query from your View

SELECT *
FROM percent_population_vaccinated
