# Daily PM2.5 and Weather Conditions Across Major U.S. Metropolitan Areas

This repository directory contains the Quarto website and reproducible report for Yukun Wang's JSC370 final project.

Website link: https://nkwyk.github.io/JSC370-project/

Project pages:

- `index.qmd`: project summary and links.
- `visualizations.qmd`: interactive Plotly visualizations for Homework 5.
- `report.qmd`: written report source, rendered to both HTML and PDF.
- `about.qmd`: data and reproducibility notes.

Data sources:

- EPA AQS daily PM2.5 monitor data.
- EPA AQS daily wind, pressure, relative humidity, and dew point summaries.
- NOAA Climate Data Online API for maximum temperature, minimum temperature, and precipitation.

Main saved dataset:

- `pm25_weather_local_2024_2.0.csv`

To render the website locally:

```bash
quarto render
```
