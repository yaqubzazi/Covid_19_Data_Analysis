SELECT *
FROM PortfolioProject..CovidDeaths

--SELECT *
--FROM PortfolioProject..CovidVaccinations

-- The data that is going to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths

-- Comparing total cases with total deaths (Explains the chance of dying if one contracts covid in a specified country)

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS decimal)/total_cases)*100 AS DeathsPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'

-- Comparing total cases as a percentage of the population
SELECT location, date, total_cases, population, (total_cases/population)*100 as CasesPopulationPercent
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States' 

-- Looking at the % of total cases as a function of populations
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_cases INT

SELECT location, population, MAX(total_cases) as HighestCases, MAX((total_cases/population))*100 as CasesPopulationPercent
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY CasesPopulationPercent DESC

-- Countries with the highest death count
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
-- Regions with the highest death count including total death count of the world and different incomes
SELECT location, MAX(total_deaths) AS RegionDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY RegionDeathCount DESC

--Looking at amount of people that got vaccinated in the population
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3

-- Using CTE or WITH command to calculate vaccinations as a percentage of populations
With PcntPopVaccinated (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PcntPopVaccinated

-- Using a temp table to do the same type of calculations
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating a view for data visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


