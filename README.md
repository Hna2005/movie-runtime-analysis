# Movie Runtime Analysis

A data analysis project about movie runtimes and their relationship with factors such as release year, genre, popularity, ratings, and financial performance.

This project started with a simple question: are movies really as long as I think they are?

After a conversation about the runtime of *Oppenheimer*, I became curious about how movie runtimes are distributed and whether runtime has any noticeable relationship with other characteristics of a movie. I used this question as a starting point to practice data analysis with Python, Pandas, SQL, and PostgreSQL, and to build a project from the initial dataset to a structure that can later be used for visualization in Power BI.

This is my first data analysis project, so the main goal was to apply what I had learned to a real dataset and learn through the process.


## Project Overview

The main focus of this project is movie runtime. I wanted to see how runtime is distributed across movies and whether it has any noticeable relationship with other characteristics of a movie.

The analysis looks at runtime from different perspectives, including release year, decade, genre, country, popularity, ratings, and financial performance. I also created runtime categories to make it easier to compare movies with different lengths.

The project started with the original dataset and gradually moved through data auditing, cleaning, exploratory analysis, SQL transformations, database modeling, and preparation for visualization in Power BI.


## Research Questions

The main questions I wanted to explore were:

- How are movie runtimes distributed?
- How has the typical runtime of movies changed over the years?
- Are there noticeable differences in runtime between genres?
- Does movie runtime vary across production countries?
- Is there any relationship between runtime and popularity?
- Is there any relationship between runtime and movie ratings?
- How does runtime relate to revenue and estimated gross profit?
- How do different runtime categories compare with each other?


## Dataset

The project uses the `movies_metadata.csv` dataset, which contains metadata for movies along with information such as runtime, release date, genres, popularity, ratings, budget, and revenue.

The original dataset contains **45,466 rows and 24 columns**.

Some of the columns used in the analysis include:

| Column | Description |
|---|---|
| `id` | Movie identifier |
| `original_title` | Original movie title |
| `original_language` | Original language of the movie |
| `release_date` | Movie release date |
| `runtime` | Movie runtime in minutes |
| `genres` | Genres associated with the movie |
| `production_countries` | Countries involved in production |
| `popularity` | Popularity score in the dataset |
| `vote_average` | Average user rating |
| `vote_count` | Number of votes |
| `budget` | Reported movie budget |
| `revenue` | Reported movie revenue |

The original dataset also contains several columns with nested or JSON-like information, such as genres, production companies, production countries, and spoken languages. These fields required additional processing before they could be used effectively in the database.


## Data Cleaning

Before starting the main analysis, I inspected the original dataset to understand its structure and identify data quality problems.

I used Python and Pandas for the initial cleaning process.

The main issues I found were:

- Duplicate movie records
- Incorrect data types
- Corrupted rows
- Missing values
- Zero values in some numeric columns
- JSON-like columns containing nested information
- Unusual runtime values

### Duplicate Rows

I checked both completely duplicated rows and duplicated movie IDs.

After reviewing the duplicated records, duplicate movie IDs were removed so that each movie would appear only once in the cleaned dataset.

### Data Types

Several columns were converted to appropriate data types.

The following columns were converted to numeric values:

- `budget`
- `id`
- `popularity`
- `revenue`
- `runtime`
- `vote_average`
- `vote_count`

`release_date` was converted to a datetime column.

The Boolean columns `adult` and `video` were also converted to Boolean values after checking their contents.

### Corrupted Rows

During the cleaning process, three rows were found where the `adult` column contained movie description text instead of `True` or `False`.

The values in these rows were shifted into the wrong columns, indicating that the rows were incorrectly parsed.

Since their original values could not be reliably reconstructed, these three rows were removed.

### JSON-like Columns

Several columns in the original dataset contained strings representing dictionaries or lists, including:

- `belongs_to_collection`
- `genres`
- `production_companies`
- `production_countries`
- `spoken_languages`

I parsed these values and extracted the relevant information into separate columns:

- `collection`
- `genre_names`
- `company_names`
- `country_names`
- `language_names`

Empty lists were converted to missing values.

The original JSON-like columns were removed after the extracted information had been checked.

### Zero Values

Zero does not have the same meaning for every variable, so I did not replace all zero values automatically.

For `budget`, `revenue`, and `runtime`, zero was treated as missing information and replaced with `NaN`.

For `vote_average` and `vote_count`, zero values were kept because they can represent valid observations in the dataset.

| Column | Decision |
|---|---|
| `runtime` | Replace `0` with `NaN` |
| `budget` | Replace `0` with `NaN` |
| `revenue` | Replace `0` with `NaN` |
| `vote_average` | Keep `0` |
| `vote_count` | Keep `0` |

I also inspected extreme values instead of removing them automatically. Some unusually large values may represent real observations, so they were retained for further analysis.

### Filtering

.Movies with `adult = True` were excluded to keep the analysis focused on general-audience films

I also kept only movies with `status = Released`. Movies with other statuses could contain incomplete or provisional information and were not suitable for the main analysis.

After the cleaning and filtering steps, the dataset contained **44,977 rows and 20 columns**.

### Release Year and Decade

Two additional columns were created from `release_date`:

- `release_year`
- `release_decade`

These columns make it easier to compare movie runtimes across individual years and decades.


## Feature Engineering

After cleaning the dataset, I created additional features that are useful for the analysis and database model.

### Runtime Category

Movies were divided into four runtime categories:

| Runtime | Category |
|---|---|
| `< 40 minutes` | Short Film |
| `40–59 minutes` | Medium-Length |
| `60–149 minutes` | Standard Feature |
| `≥ 150 minutes` | Long Feature |

These categories make it easier to compare movies based on their length instead of relying only on the raw runtime value.

### Estimated Gross Profit

I created a `profit` feature using:

`profit = revenue - budget`

For this project, this is treated as **Estimated Gross Profit**.

It should not be interpreted as the actual net profit of a movie. The dataset does not contain costs such as marketing, distribution, or the share of revenue received by cinemas.

Therefore, this feature is only an estimate based on the two financial fields available in the dataset.

### Revenue-to-Budget Ratio

I also created:

`revenue_budget_ratio = revenue / budget`

The calculation is only performed when the budget is greater than zero.

This ratio is useful for comparing reported revenue relative to reported budget, but it is not treated as a complete ROI calculation because the dataset does not contain all of the costs involved in producing and distributing a movie.

## PostgreSQL and SQL

After the data was cleaned in Python, I moved the processed data into PostgreSQL.

The cleaned data was first loaded into a staging table called `staging_movies`. This table acts as an intermediate step before the data is separated into the final fact and dimension tables.

The database was then organized into a fact-and-dimension structure.

## Data Model

The database follows a fact-and-dimension structure.

At the center of the model is `fact_movies`, which contains movie-level information and references the related dimensions.

A simplified view of the model is:

```text
                         dim_date
                            |
                            |
dim_language -----> fact_movies <----- dim_runtime_category
                            |
                            |
              +-------------+-------------+
              |             |             |
              ↓             ↓             ↓
        bridge_genre  bridge_company  bridge_country
              |             |             |
              ↓             ↓             ↓
         dim_genre     dim_company    dim_country
```

The main tables are:

* `fact_movies`
* `dim_date`
* `dim_language`
* `dim_runtime_category`
* `dim_genre`
* `dim_company`
* `dim_country`
* `bridge_genre`
* `bridge_company`
* `bridge_country`

### Fact Table

`fact_movies` contains the main movie-level information used in the analysis, including:

* Movie ID
* Title
* Release date reference
* Language reference
* Runtime category reference
* Runtime
* Budget
* Revenue
* Estimated gross profit
* Revenue-to-budget ratio
* Popularity
* Vote average
* Vote count

Foreign keys are used to connect movie records to the corresponding dimensions.

### Dimension Tables

The dimension tables store information that can be shared by multiple movies.

For example, `dim_date` stores release date, year, and decade information, while `dim_language` stores the language information used by the movies.

`dim_runtime_category` contains the four runtime categories used in the project.

### Many-to-Many Relationships

Genres, production companies, and production countries can have many-to-many relationships with movies.

For example, one movie can have several genres, while the same genre can be associated with many movies.

Instead of storing all genres in one field in the fact table, separate dimension and bridge tables were created.

The same approach was used for production companies and production countries.

This keeps the relationships between movies and their attributes separate and makes the data easier to query.

## Data Quality Checks

After creating the database structure, I added SQL checks to make sure that the relationships between the tables were valid.

The checks include:

* Comparing the number of records in `staging_movies` and `fact_movies`
* Checking for duplicated movie IDs
* Checking for invalid date references
* Checking for invalid language references
* Checking for invalid runtime category references
* Validating foreign key references in all bridge tables (genre, company, country)
* Checking genre relationship counts

These checks help verify that the database does not contain broken references after the transformation and modeling steps.

## Exploratory Data Analysis

After cleaning the dataset, I used Python and Pandas to explore movie runtimes and their relationship with other variables.

The main focus of the EDA was to understand the distribution of runtime first and then compare it with other movie characteristics.

The analysis covers:

* Runtime distribution
* Runtime across release years
* Runtime across decades
* Runtime across genres
* Runtime across production countries
* Runtime and popularity
* Runtime and ratings
* Runtime and financial performance
* Comparison of runtime categories

### Runtime Distribution

Runtime is the main variable of the project.

I first looked at its basic statistics and distribution to understand what a typical movie runtime looks like in the dataset.

I also checked unusually short and long movies instead of removing them automatically. This is important because some of these values may represent real movies, while others may be unusual observations in the dataset.

For this reason, the mean, median, quartiles, and overall distribution are considered together when interpreting runtime.

### Runtime Over Time

I used `release_year` and `release_decade` to examine whether movie runtimes have changed over time.

This allows the analysis to compare individual years as well as broader periods.

### Runtime and Genre

Movies can have more than one genre, so genre information was separated from the main movie table during the database modeling stage.

This makes it possible to compare runtime patterns across genres without treating the original genre field as a single text value.

### Runtime and Production Country

Production country information was also separated from the main movie table.

Since a movie can be associated with more than one production country, the country information is connected to movies through a bridge table.

This allows runtime patterns to be compared across countries while preserving the original relationships.

### Runtime and Popularity

I also explored whether movies with different runtimes tend to have different popularity scores.

This is treated as an association in the data, not as evidence that runtime causes a movie to become more or less popular.

### Runtime and Ratings

The relationship between runtime and `vote_average` was also examined.

I considered `vote_count` alongside the average rating because an average rating based on a small number of votes can represent a different situation from the same rating based on a much larger number of votes.

### Runtime and Financial Performance

The financial part of the analysis uses:

* `budget`
* `revenue`
* `profit`
* `revenue_budget_ratio`

The `profit` variable is calculated as `revenue - budget` and is used in this project as an estimated gross profit.

It does not represent the actual net profit of a movie because the dataset does not include costs such as marketing, distribution, or the share of revenue received by cinemas.

The financial analysis therefore focuses on the relationships between the available financial variables.

## Power BI Dashboard

The Power BI dashboard is the final visualization stage of the project and is currently in progress.

The dashboard is planned to make the results of the analysis easier to explore without having to work directly with the notebooks or SQL queries.

The main areas of the dashboard will include:

* Movie runtime distribution
* Runtime changes over time
* Runtime by genre
* Runtime category comparisons
* Runtime and popularity
* Runtime and ratings
* Runtime and reported financial performance

The final Power BI report will be added to the `powerbi` folder after it is completed.

## Key Findings

*To be completed after the final analysis and dashboard are finished.*

## Project Structure

```text
movie-runtime-analysis/
│
├── data/
│   ├── raw.csv
│   └── interim.csv
│
├── notebooks/
│   ├── 01-data-audit.ipynb
│   ├── 02-data-cleaning.ipynb
│   └── 03-eda.ipynb
│
├── sql/
│   ├── 01-data-modeling.sql
│   ├── 02-data-quality-checks.sql
│   └── 03-analysis.sql
│
├── powerbi/
│
└── README.md
```

### Notebooks

* `01-data-audit.ipynb` — initial inspection of the dataset and data quality issues
* `02-data-cleaning.ipynb` — cleaning and preparation of the dataset
* `03-eda.ipynb` — exploratory analysis and visualization

### SQL

* `01-data-modeling.sql` — creation and population of the PostgreSQL data model
* `02-data-quality-checks.sql` — checks for data consistency and invalid references
* `03-analysis.sql` — SQL analysis queries

### Data

* `raw.csv` — original dataset used as the starting point for the project
* `interim.csv` — cleaned dataset used for the database stage

The original `movies_metadata.csv` file is not stored in the repository.

### Power BI

The `powerbi` folder will contain the Power BI report after the dashboard is completed.

## Tools and Technologies

* **Python** — data cleaning and exploratory analysis
* **Pandas** — data manipulation and analysis
* **NumPy** — numerical operations
* **Matplotlib** — data visualization
* **PostgreSQL** — database storage and SQL analysis
* **SQL** — data modeling, data quality checks, and analysis
* **Power BI** — dashboard and final visualization
* **Jupyter Notebook** — Python-based analysis
* **Git & GitHub** — version control

## How to Run

### 1. Clone the repository

```bash
git clone https://github.com/Hna2005/movie-runtime-analysis.git
cd movie-runtime-analysis
```

### 2. Set up the Python environment

Create a Python environment and install the libraries required by the notebooks.

The notebooks can then be opened and run using Jupyter Notebook or JupyterLab.

### 3. Run the notebooks

The recommended order is:

1. `01-data-audit.ipynb`
2. `02-data-cleaning.ipynb`
3. `03-eda.ipynb`

The cleaning notebook uses the dataset in the `data` folder and produces the processed dataset used in the following stages.

### 4. Set up PostgreSQL

Create a PostgreSQL database and run the SQL files in this order:

1. `01-data-modeling.sql`
2. `02-data-quality-checks.sql`
3. `03-analysis.sql`

The data model should be created before running the data quality checks and analysis queries.

### 5. Open the Power BI report

The Power BI report will be added to the `powerbi` folder after the dashboard is completed.

## Limitations

There are several limitations that should be considered when interpreting the results.

### Dataset Limitations

The dataset contains missing values and unusual observations.

Runtime contains some very small and very large values, which can affect statistics such as the mean.

Some financial fields are also missing for a number of movies, so financial analysis cannot represent the complete dataset.

### Financial Data

The `profit` feature is calculated as:

`revenue - budget`

This is only an estimate based on the available data.

It does not represent actual net profit because marketing, distribution, theater revenue sharing, and other costs are not included.

Similarly, `revenue_budget_ratio` should not be interpreted as a complete ROI calculation.

### Interpretation

Relationships found in the data should not automatically be interpreted as causal relationships.

For example, if runtime and popularity show a relationship, this does not mean that changing the runtime of a movie would directly change its popularity.

## Future Improvements

This project is still open to further development.

Possible next steps include:

* Completing the Power BI dashboard
* Adding more detailed visual analysis
* Expanding the SQL analysis
* Exploring additional relationships between movie characteristics
* Taking a closer look at unusual runtime values
* Adding more detailed documentation for the database model
* Exploring statistical or machine learning methods for some of the questions raised by the project

## Project Status

The project is currently in development.

### Completed

* [x] Initial data audit
* [x] Data cleaning
* [x] Exploratory data analysis
* [x] PostgreSQL data modeling
* [x] Data quality checks

### In Progress

* [ ] SQL analysis
* [ ] Power BI dashboard
* [ ] Final findings and conclusions
* [ ] Final project documentation

## Author

*My first step into data analysis — and hopefully not the last.*

*It started with a question about movie length.*

**Hana**
