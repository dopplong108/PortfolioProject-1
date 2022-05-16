SELECT population	
FROM PortfolioProject..CovidDeaths$
ORDER BY location, date 


SELECT *
FROM PortfolioProject..CovidVaccinations$
ORDER BY location, date


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1,2

--THE TOTAL CASES TOTAL DEATHS AND THE DEATH RATE PER CASE IN USA

SELECT location, date, total_cases, total_deaths,ROUND((total_deaths/total_cases)*100,2) AS death_percentage_per_case
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%states%'
ORDER BY 1,2 

--THE TOTAL CASES TOTAL DEATHS AND THE DEATH RATE PER CASE IN VIETNAM

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS death_percentage_per_case
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%vietnam%'
ORDER BY 1,2 


-- FIND COUNTRIES WITH THE HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT location, population, MAX(total_cases) AS the_highest_infection_count, ROUND(MAX((total_deaths/total_cases)*100),2) AS the_highest_death_percentage_per_case
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY the_highest_death_percentage_per_case DESC



-- FIND COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION AND THE TOTAL DEATHS (ONLY FOR IDENTIFIED NATIONALITY VICTIMS) --Some people unfortunately died before they have their nationality identified.


SELECT location, MAX(CAST( total_deaths AS int))  AS the_highest_death_count_per_ctry,
SUM(CAST( total_deaths AS int))  AS the_total_death_count_per_ctry
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY  the_highest_death_count_per_ctry DESC


-- FIND CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION AND THE TOTAL DEATHS (ONLY FOR IDENTIFIED NATIONALITY VICTIMS)


SELECT continent, MAX(CAST(total_deaths AS int))  AS the_highest_death_count_per_continent,
SUM(CAST(total_deaths AS int))  AS the_total_death_count_per_continent
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY  continent
ORDER BY the_total_death_count_per_continent DESC

-- GLOBAL NUMBER SHOWING TOTAL NUMBER OF NEW CASES, THE TOTAL NUMBER OF DEATHS AND THE DEATH RATE ON EACH DAY


SELECT date, SUM(CAST(new_cases AS int))  AS the_total_new_cases_itw, 
SUM(CAST(total_deaths AS int))  AS the_total_deaths_itw, 
SUM(CAST(new_cases AS int) )/ SUM(CAST(total_deaths AS int))
AS the_highest_death_rate_per_case
FROM PortfolioProject..CovidDeaths$	
WHERE location IS NOT NULL
GROUP BY date
ORDER BY 1

--OVERALL CASES, DEATHS AND DEATH RATE

SELECT
SUM(CAST(new_cases AS int))  AS the_total_new_cases_itw, 
SUM(CAST(total_deaths AS int))  AS the_total_deaths_itw, 
SUM(CAST(total_deaths AS int)) / SUM(CAST(new_cases AS int) )
AS the_world_death_rate_per_case
FROM PortfolioProject..CovidDeaths$	
WHERE location IS NOT NULL
ORDER BY 1

--LOOKING AT TOTAL PUPULATION AND CACCINATIONS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location ,  dea.date)  
AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ dea

INNER JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--USE CTE 
WITH pop_vs_vac (
Continent, Location, Date, Population, new_vaccinations, rolling_people_vaccinated, rolling_people_deaths)
AS(

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location ,  dea.date)  
AS rolling_people_vaccinated,
SUM(CONVERT(int, total_deaths)) OVER (PARTITION BY dea.location ORDER BY dea.location ,  dea.date)  
AS rolling_people_deaths
FROM PortfolioProject..CovidDeaths$ dea

INNER JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

)
--THE VACCINATED RATE IN PER DATE


SELECT * , ROUND((
(rolling_people_vaccinated/ (population - rolling_people_deaths))
)*100,2) AS vaccinated_rate
FROM pop_vs_vac



--TEMP TABLE
CREATE TABLE #percent_population_vaccinated
(
Continent NVARCHAR (255),
Location NVARCHAR (255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
Rolling_people_vaccinated NUMERIC,
Rolling_people_deaths NUMERIC
)
INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location ,  dea.date)  
AS rolling_people_vaccinated,
SUM(CONVERT(int, total_deaths)) OVER (PARTITION BY dea.location ORDER BY dea.location ,  dea.date)  
AS rolling_people_deaths
FROM PortfolioProject..CovidDeaths$ dea

INNER JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * , ROUND((
(rolling_people_vaccinated/ (population - rolling_people_deaths))
)*100,2) AS vaccinated_rate
FROM #percent_population_vaccinated

-- CREATING VIEW

CREATE VIEW percent_population_vaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location ,  dea.date)  
AS rolling_people_vaccinated,
SUM(CONVERT(int, total_deaths)) OVER (PARTITION BY dea.location ORDER BY dea.location ,  dea.date)  
AS rolling_people_deaths
FROM PortfolioProject..CovidDeaths$ dea

INNER JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- SQL fOR TABLEAU ILLUSTRATION
--#1 THE TOTAL CASES TOTAL DEATHS AND THE DEATH RATE PER CASE OVER THE WORLD


SELECT location, population,  
SUM(CAST(total_deaths AS BIGINT)) AS total_deaths, SUM(CAST(total_cases AS BIGINT))
AS total_infected
FROM PortfolioProject..CovidDeaths$	
WHERE location IS NOT NULL AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location, population
ORDER BY 3 DESC



--#2 RATIO OF DEATH tO POPULATION FROM 24 FEB2020 TO 24FEB 2021 ((ONLY FOR IDENTIFIED NATIONALITY DEATHS)


SELECT location,  100 *  (SUM(CONVERT(bigint,total_deaths)/ (population)  ) ) 
AS the_rate_people_overcome_covide

FROM PortfolioProject..CovidDeaths$
WHERE  location IS NOT NULL AND location NOT IN ('World', 'European Union', 'International') 
GROUP BY location

ORDER BY 2 DESC


--#3 TOP 5 CONTINENTS WITH THE HIGHEST TOTAL DEATHS


SELECT continent, SUM(CONVERT(bigint, total_deaths))
AS the_death_deaths
FROM PortfolioProject..CovidDeaths$
WHERE  continent IS NOT NULL AND location NOT IN ('World', 'European Union', 'International') 
GROUP BY continent
ORDER BY 2 DESC



--#4 TREND  OF THE WORLD

SELECT location, date , MAX(total_cases)  AS the_highest_inffection_count 
FROM PortfolioProject..CovidDeaths$	
WHERE  continent IS NOT NULL AND location NOT IN ('World', 'European Union', 'International') 
GROUP BY location,date
ORDER BY 3 DESC
