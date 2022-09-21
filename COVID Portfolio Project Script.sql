
-- Select the Data that we are using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CoronavirusPortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

----------------------------------------------------------

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if your contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CoronavirusPortfolioProject..CovidDeaths
WHERE Location like'%states%' AND continent is not null
ORDER BY 1,2

----------------------------------------------------------

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid

SELECT Location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM CoronavirusPortfolioProject..CovidDeaths
WHERE Location = 'United States' AND continent is not null

ORDER BY 1,2

----------------------------------------------------------

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT Location, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CoronavirusPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

----------------------------------------------------------

-- Looking at Countries with Highest Death Count per Population

SELECT Location, MAX(cast(Total_Deaths as int)) AS TotalDeathCount
FROM CoronavirusPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

----------------------------------------------------------

-- **LET'S BREAK THINGS DOWN BY CONTINENT**


-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(Total_Deaths as int)) AS TotalDeathCount
FROM CoronavirusPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

----------------------------------------------------------

-- Global Numbers

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CoronavirusPortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

----------------------------------------------------------

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM CoronavirusPortfolioProject..CovidDeaths dea
JOIN CoronavirusPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null AND dea.location IN('United States', 'Mexico', 'Canada')
ORDER BY 2,3

----------------------------------------------------------

-- Using a CTE to display a rolling percentage of the population that is vaccinated for the US, Canada, and Mexico

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM CoronavirusPortfolioProject..CovidDeaths dea
JOIN CoronavirusPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null AND dea.location IN('United States', 'Mexico', 'Canada')
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentPopulationVaccinated
FROM PopVsVac

----------------------------------------------------------

-- Using a TEMP TABLE to display a rolling percentage of the population that is vaccinated for the US, Canada, and Mexico

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM CoronavirusPortfolioProject..CovidDeaths dea
JOIN CoronavirusPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null AND dea.location IN('United States', 'Mexico', 'Canada')
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentPopulationVaccinated
FROM #PercentPopulationVaccinated

----------------------------------------------------------

-- Creating a View to store data for later viz

CREATE VIEW RollingPercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM CoronavirusPortfolioProject..CovidDeaths dea
JOIN CoronavirusPortfolioProject..
CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null AND dea.location IN('United States', 'Mexico', 'Canada')
--ORDER BY 2,3


SELECT *
FROM RollingPercentPopulationVaccinated


-- **Queries for Tableau Viz**

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CoronavirusPortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From CoronavirusPortfolioProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CoronavirusPortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CoronavirusPortfolioProject..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc