USE PortfolioProject
GO

SELECT 
	location,date,total_cases,new_cases,total_deaths,population
FROM 
	covidDeaths$
ORDER BY 
	1,2;

SELECT 
	*
FROM 
	covidVacinations$
ORDER BY 
	3,4;

-- Total cases vs Total deaths with death percentage 

SELECT 
	location
	,date
	,total_cases
	,total_deaths
	,(total_deaths / total_cases)*100 as death_percentage 
FROM 
	covidDeaths$
--WHERE location LIKE	'UNITED KINGDOM'
ORDER BY 
	1,2;

-- Total Cases vs Population with infection rate 
SELECT 
	location
	,date
	,total_cases
	,total_deaths
	,population
	,(total_cases / population)*100 as infection_rate 
FROM 
	covidDeaths$
WHERE continent is not null 
ORDER BY 
	1,2;

-- Countries with highest infection rate compared to population 
SELECT 
	location
	,max(total_cases) MAX_CASES
	,population
	,MAX((total_cases / population)*100) as infection_rate 
FROM 
	covidDeaths$
WHERE continent is not null 
GROUP BY 
	location
	,population
ORDER BY 
	infection_rate desc;


-- Countries with highest DEATH rate compared to population 
SELECT 
	location
	,max(CAST(total_deaths AS int)) MAX_DEATHS
	,population
	,MAX((total_deaths / population)*100) as DEATH_RATE 
FROM 
	covidDeaths$
WHERE continent is not null 
GROUP BY 
	location
	,population
ORDER BY 
	MAX_DEATHS desc;

-- total deaths by contintent 
SELECT 
	continent
	,max(CAST(total_deaths AS int)) MAX_DEATHS
	,MAX((total_deaths / population)*100) as DEATH_RATE 
FROM 
	covidDeaths$
WHERE continent is not null 
GROUP BY 
	continent
ORDER BY 
	MAX_DEATHS desc;

-- GLOBAL NUMBERS 

SELECT 
	--DATE
	SUM(NEW_CASES) total_daily_cases
	,SUM(cast(new_deaths as int)) total_daily_deaths
	,(SUM(cast(new_deaths as int)) / SUM(NEW_CASES) )*100 AS DEATH_PERCENTAGE
FROM 
	covidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 
	1,2;

-- vaccinations 

SELECT 
	* 
FROM 
	covidDeaths$ CD 
LEFT JOIN covidVacinations$ CV 
ON CD.continent = CV.continent AND CD.location = CV.location AND CD.date = CV.date

-- TOTAL POPULATION VS VACCINATION

SELECT 
	 cd.continent
	,cd.location
	,cd.date
	,cd.population
	,new_vaccinations
	,SUM(convert(bigint,CV.new_vaccinations)) OVER(PARTITION BY CD.LOCATION ORDER BY CD.LOCATION,CD.DATE) as Running_vaccination_total
FROM 
	covidDeaths$ CD 
LEFT JOIN covidVacinations$ CV 
ON CD.continent = CV.continent AND CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL 
ORDER BY 
	2,3
	

-- CTE

WITH PopVSVac (continent,Location,Date,population,new_vaccinations,Running_vaccination_total)
as (
SELECT 
	 cd.continent
	,cd.location
	,cd.date
	,cd.population
	,new_vaccinations
	,SUM(convert(bigint,CV.new_vaccinations)) OVER(PARTITION BY CD.LOCATION ORDER BY CD.LOCATION,CD.DATE) as Running_vaccination_total
FROM 
	covidDeaths$ CD 
LEFT JOIN covidVacinations$ CV 
ON CD.continent = CV.continent AND CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL 
	)
select *,(Running_vaccination_total / population)*100 as vaccination_vs_population from PopVSVac


-- CREATING TABLE 
-- Using Temp Table to perform Calculation on Partition By in previous query

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
Select 
	  CD.continent
	, CD.location
	, CD.date
	, CD.population
	, CV.new_vaccinations
, SUM(CONVERT(bigint,CV.new_vaccinations)) OVER (Partition by CD.Location Order by CD.location, CD.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covidDeaths$ CD
Join covidVacinations$ CV
	On CD.location = CV.location
	and CD.date = CV.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- VIEWS FOR DATA VISUALTIONS 

CREATE VIEW PERCENT_POPULATION_VACCINATED AS 

SELECT 
	 cd.continent
	,cd.location
	,cd.date
	,cd.population
	,new_vaccinations
	,SUM(convert(bigint,CV.new_vaccinations)) OVER(PARTITION BY CD.LOCATION ORDER BY CD.LOCATION,CD.DATE) as Running_vaccination_total
FROM 
	covidDeaths$ CD 
LEFT JOIN covidVacinations$ CV 
ON CD.continent = CV.continent AND CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL 

SELECT * FROM PERCENT_POPULATION_VACCINATED