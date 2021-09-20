CREATE TABLE public.covidvaccination
(
	iso_code text,
    continent text,
    location text,
	date date,
    new_tests integer,
    total_tests integer,
    total_tests_per_thousand double precision,
    new_tests_per_thousand double precision,
    new_tests_smoothed integer,
	new_tests_smoothed_per_thousand double precision,
	positive_rate double precision,
	tests_per_case	double precision,
	tests_units	text,
	total_vaccinations BIGINT,
	people_vaccinated BIGINT,
	people_fully_vaccinated	BIGINT,
	total_boosters integer,
	new_vaccinations integer,
	new_vaccinations_smoothed	integer,
	total_vaccinations_per_hundred	double precision,
	people_vaccinated_per_hundred	double precision,
	people_fully_vaccinated_per_hundred	double precision,
	total_boosters_per_hundred	double precision,
	new_vaccinations_smoothed_per_million	double precision,
	stringency_index	double precision,
	population_density	double precision,
	median_age	double precision,
	aged_65_older	double precision,
	aged_70_older	double precision,
	gdp_per_capita	double precision,
	extreme_poverty	double precision,
	cardiovasc_death_rate	double precision,
	diabetes_prevalence	double precision,
	female_smokers	double precision,
	male_smokers	double precision,		
	handwashing_facilities	double precision,
	hospital_beds_per_thousand	double precision,
	life_expectancy	double precision,
	human_development_index	double precision,
	excess_mortality double precision		

);

--check if the table has been created
SELECT * FROM covidvaccination;
--Successful
--Copy data from csv file
COPY Public.covidvaccination FROM 'C:\Users\DELL\Downloads\CovidVaccination.csv' DELIMITER ',' HEADER CSV;
--Re-checck table again
SELECT * FROM covidvaccination;


CREATE TABLE public.coviddeath
(
	iso_code text,
    continent text,
    location text,
	date date,
	population	BIGINT	,
	total_cases	INT	,
	new_cases	INT	,
	new_cases_smoothed	double precision	,
	total_deaths	BIGINT	,
	new_deaths	INT	,
	new_deaths_smoothed	double precision	,
	total_cases_per_million	double precision	,
	new_cases_per_million	double precision	,
	new_cases_smoothed_per_million	double precision	,
	total_deaths_per_million	double precision	,
	new_deaths_per_million	double precision	,
	new_deaths_smoothed_per_million	double precision	,
	reproduction_rate double precision	,
	icu_patients	BIGINT	,
	icu_patients_per_million	double precision	,
	hosp_patients	BIGINT	,
	hosp_patients_per_million	double precision	,
	weekly_icu_admissions	double precision	,
	weekly_icu_admissions_per_million	double precision	,
	weekly_hosp_admissions	double precision	,
	weekly_hosp_admissions_per_million double precision	

);

SELECT * FROM Coviddeath;
--following same procedure
COPY Public.coviddeath FROM 'C:\Users\DELL\Downloads\CovidDeath.csv' DELIMITER ',' HEADER CSV;
--Re-run the select statement
SELECT * FROM Coviddeath
WHERE continent IS NOT NULL;


SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM Coviddeath
ORDER BY 1,2;

ALTER TABLE Coviddeath 
ALTER COLUMN total_deaths TYPE INT;
--TOTAL CASES VERSUS TOTAL DEATHS
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS DECIMAL)/total_cases)*100 as DeathPercentage ,population 
FROM Coviddeath
ORDER BY 1,2;

--likelihood of dying in Nigrian in < 3%
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS DECIMAL)/total_cases)*100 as DeathPercentage ,population 
FROM Coviddeath
WHERE LOCATION = 'Nigeria'
ORDER BY 1,2;

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS DECIMAL)/total_cases)*100 as DeathPercentage ,population 
FROM Coviddeath
WHERE LOCATION = 'United states'
ORDER BY 1,2;

--showing what percentage of population got Covid.
SELECT location, date, population, total_cases, (CAST(total_cases AS DECIMAL)/population)*100 as PercentPolpulationInfected
FROM Coviddeath
WHERE LOCATION = 'Nigeria'
ORDER BY 1,2;

--countries with highest infection rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((CAST(total_cases AS DECIMAL)/population))*100 as PercentPolpulationInfected 
FROM Coviddeath
GROUP BY location, population
ORDER BY PercentPolpulationInfected DESC;

--Checking for countries with highest deaths
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM Coviddeath
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Working with continents

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM Coviddeath
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM Coviddeath
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

SELECT SUM(new_cases) AS total_case, SUM(new_deaths) AS total_death, SUM(CAST(new_deaths AS DECIMAL))/SUM(new_cases) * 100 AS DeathPercent
FROM Coviddeath
WHERE continent is not null
--GROUP BY date
ORDER BY Deathpercent;

--Vaccination table.
SELECT * FROM Coviddeath
JOIN Covidvaccination
ON Coviddeath.location = Covidvaccination.location
AND Coviddeath.date = Covidvaccination.date;

--Total population versus vaccination
SELECT coviddeath.continent, coviddeath.location, coviddeath.date, population, new_vaccinations FROM Coviddeath
JOIN Covidvaccination
ON Coviddeath.location = Covidvaccination.location
AND Coviddeath.date = Covidvaccination.date
WHERE coviddeath.continent IS NOT NULL
ORDER BY 1,2, 3;

--Adding to the new vaccination column for previous days.
SELECT coviddeath.continent, coviddeath.location, coviddeath.date, population, new_vaccinations, 
SUM(new_vaccinations) OVER (PARTITION BY coviddeath.location ORDER BY Coviddeath.location, Coviddeath.date) AS RollingPeopleVaccinated
FROM Coviddeath
JOIN Covidvaccination
ON Coviddeath.location = Covidvaccination.location
AND Coviddeath.date = Covidvaccination.date
WHERE coviddeath.continent IS NOT NULL
ORDER BY 2, 3;

--To check for total vaccination per population , we use CTE
WITH PopsVac (continent, location, date, population, new_vaccination, RollingPeopleVaccinated)
AS
(
	SELECT coviddeath.continent, coviddeath.location, coviddeath.date, population, new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY coviddeath.location ORDER BY Coviddeath.location, Coviddeath.date) AS RollingPeopleVaccinated
	FROM Coviddeath
	JOIN Covidvaccination
	ON Coviddeath.location = Covidvaccination.location
	AND Coviddeath.date = Covidvaccination.date
	WHERE coviddeath.continent IS NOT NULL
	--ORDER BY 2, 3;
)
SELECT *, (CAST(RollingPeopleVaccinated AS DECIMAL)/population)*100
FROM PopsVac;



--TEMP TABLE
DROP TABLE IF EXISTS PercentpopulationVaccinated;
CREATE TABLE PercentpopulationVaccinated(
	continent VARCHAR(255),
	locaton VARCHAR(255),
	date date,
	population BIGINT,
	new_vaccination INT,
	RollingPeopleVaccinated BIGINT
	);
	
INSERT INTO PercentpopulationVaccinated
SELECT coviddeath.continent, coviddeath.location, coviddeath.date, population, new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY coviddeath.location ORDER BY Coviddeath.location, Coviddeath.date) AS RollingPeopleVaccinated
	FROM Coviddeath
	JOIN Covidvaccination
	ON Coviddeath.location = Covidvaccination.location
	AND Coviddeath.date = Covidvaccination.date
	WHERE coviddeath.continent IS NOT NULL;
	--ORDER BY 2, 3;

SELECT *, (CAST(RollingPeopleVaccinated AS DECIMAL)/population)*100
FROM PercentpopulationVaccinated;

--Creating Views.
CREATE VIEW PercentVaccinationView AS
	SELECT coviddeath.continent, coviddeath.location, coviddeath.date, population, new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY coviddeath.location ORDER BY Coviddeath.location, Coviddeath.date) AS RollingPeopleVaccinated
	FROM Coviddeath
	JOIN Covidvaccination
	ON Coviddeath.location = Covidvaccination.location
	AND Coviddeath.date = Covidvaccination.date
	WHERE coviddeath.continent IS NOT NULL;

SELECT * FROM PercentVaccinationView;
