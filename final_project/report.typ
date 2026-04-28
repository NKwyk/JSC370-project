// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: doc => article(
  title: [Daily PM2.5 and Weather Conditions Across Major U.S. Metropolitan Areas in 2024],
  authors: (
    ( name: [Yukun Wang],
      affiliation: [],
      email: [] ),
    ),
  date: [2026-04-26],
  sectionnumbering: "1.1.a",
  toc: true,
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

= Introduction
<introduction>
PM2.5 refers to fine particulate matter with diameter less than or equal to 2.5 micrometers. These particles are small enough to enter the respiratory system, so elevated PM2.5 is a public health concern. In my midterm project, I described 2024 PM2.5 patterns across major U.S. metropolitan areas and examined how pollution changed by place, season, and weather conditions.

This final project extends that work from exploratory analysis to prediction. The main research question is:

#quote(block: true)[
How are daily PM2.5 levels associated with temperature, precipitation, wind, pressure, and humidity across major U.S. metropolitan areas in 2024, and can these weather and location features help predict high-pollution days?
]

I study two related modeling tasks. First, I predict daily mean PM2.5 as a continuous outcome. Second, I classify whether a monitor-day exceeds 35 ug/m3, a high-pollution threshold used in the midterm feedback and final project plan.

= Methods
<methods>
== Data
<data>
The dataset used in this project was generated by combining air pollution data from the EPA Air Quality System (AQS) with weather data from both EPA AQS and the NOAA Climate Data Online (CDO) API. The EPA AQS data provided daily PM2.5 monitor-level observations, as well as daily wind speed, barometric pressure, and relative humidity/dew point variables. The NOAA CDO API was used to retrieve daily maximum temperature, minimum temperature, and precipitation for selected weather stations representing major U.S. metropolitan areas. These data sources were combined so that each PM2.5 monitor-day observation could be linked with local weather, geographic, and temporal information.

After the raw EPA and NOAA data were merged, the project analysis began from the cleaned CSV file `pm25_weather_local_2024_2.0.csv`. In this step, the date variable was parsed into datetime format, and several additional variables were created for analysis. A binary `high_pm25_day` variable was defined to indicate whether the daily PM2.5 arithmetic mean exceeded 35 µg/m³. I also created time-based variables, including `day_of_year`, abbreviated month names, and cyclic month features using sine and cosine transformations to better represent seasonal patterns. Each monitor was identified using `state_code`, `county_code`, `site_num`, and `poc`, where POC distinguishes monitor occurrences at the same site. POC was retained only as part of the monitor identifier and was not used as an analytical predictor.

#strong[Table 1. Dataset summary.]

#table(
  columns: 2,
  align: (left,left,),
  table.header([Quantity], [Value],),
  table.hline(),
  [Monitor-day observations], [13,057],
  [Unique PM2.5 monitors], [83],
  [Metropolitan areas], [21],
  [Date range], [2024-01-01 to 2024-12-31],
  [Mean daily PM2.5], [8.84 ug/m3],
  [Median daily PM2.5], [7.72 ug/m3],
  [Maximum daily PM2.5], [130.94 ug/m3],
  [High PM2.5 days (\>35 ug/m3)], [74 (0.57%)],
)
== Feature Engineering
<feature-engineering>
The outcome for regression is `arithmetic_mean`, the daily mean PM2.5 concentration. The classification outcome is `high_pm25_day`, equal to 1 when daily PM2.5 is greater than 35 µg/m³. I use this threshold because 35 µg/m³ corresponds to the U.S. EPA 24-hour PM2.5 standard, making it a policy-relevant cutoff for identifying unusually high daily PM2.5 monitor-days. This threshold is used for classification rather than for formal regulatory attainment determinations.

Predictors include:

- Weather: maximum temperature, minimum temperature, precipitation, wind, pressure, relative humidity, and dew point.
- Space: latitude, longitude, state, and CBSA.
- Time: month, season, day of year, and cyclic month sine/cosine terms.

To avoid target leakage, PM2.5-derived fields such as `pm25_max`, `aqi`, and `high_pm25_day` are excluded from the regression predictors, and PM2.5 concentration variables are excluded from classification predictors.

== Modeling Strategy
<modeling-strategy>
I compare Random Forest and XGBoost models because they are well suited for nonlinear relationships and interactions among weather, location, and season. Both methods were covered in the course labs. Random Forest averages many decision trees to reduce variance. XGBoost builds boosted trees sequentially and uses regularization to control overfitting.

For regression, I use a 70/30 train-test split and report RMSE, MAE, and R-squared. Random Forest and XGBoost hyperparameters are selected using 3-fold cross-validation on the training set, with negative RMSE as the tuning criterion. For the regression Random Forest, the grid searches `max_features` values of 0.3, 0.6, and `"sqrt"`, and `min_samples_leaf` values of 1 and 5. For the regression XGBoost model, the grid searches `max_depth` values of 2, 4, and 6, and `learning_rate` values of 0.01 and 0.08.

For classification, I use a stratified 70/30 train-test split because the high-pollution class is rare. Classification hyperparameters are selected using stratified 3-fold cross-validation with F1 as the tuning criterion. The Random Forest classifier uses class-balanced sampling and searches the same `max_features` and `min_samples_leaf` values as the regression Random Forest. The XGBoost classifier uses `scale_pos_weight` and searches `max_depth` values of 2, 4, and 6, and `learning_rate` values of 0.01 and 0.08. After cross-validation selects the XGBoost classifier hyperparameters, I use a validation split from the training data to choose the probability threshold that maximizes F1.

= Results
<results>
== Descriptive Patterns
<descriptive-patterns>
#strong[Table 2. CBSA summary, sorted by annual mean PM2.5.]

#table(
  columns: (30.16%, 12.7%, 9.52%, 10.32%, 9.52%, 14.29%, 13.49%),
  align: (left,right,right,right,right,right,right,),
  table.header([cbsa\_name], [monitor\_days], [monitors], [mean\_pm25], [max\_pm25], [high\_pm25\_days], [high\_day\_rate],),
  table.hline(),
  [Riverside-San Bernardino-Ontario, CA], [1682], [12], [12.33], [130.94], [36], [2.14],
  [Los Angeles-Long Beach-Anaheim, CA], [1551], [10], [11.46], [68.2], [19], [1.23],
  [Cleveland-Elyria, OH], [91], [2], [11.06], [22.81], [0], [0],
  [Houston-The Woodlands-Sugar Land, TX], [1051], [6], [10.44], [46.8], [7], [0.67],
  [Dallas-Fort Worth-Arlington, TX], [328], [3], [10.14], [36.33], [1], [0.3],
)
Table 2 summarizes the metropolitan areas with the highest average daily PM2.5 concentrations in the final dataset. Riverside-San Bernardino-Ontario, CA has the highest mean PM2.5 level, with an average of 12.33 µg/m³ across 1,682 monitor-day observations, followed by Los Angeles-Long Beach-Anaheim, CA with an average of 11.46 µg/m³. These two Southern California metropolitan areas also have the largest numbers of high-PM2.5 monitor-days, suggesting that elevated PM2.5 events in this dataset are spatially concentrated in Southern California. Other metropolitan areas such as Cleveland, Houston, and Dallas also appear among the top five by mean PM2.5, but they show fewer or no high-pollution days above 35 µg/m³. Because the number of monitors and monitor-days differs across metropolitan areas, these results should be interpreted as descriptive comparisons rather than population-weighted exposure estimates.

#figure([
#box(image("report_files/figure-typst/fig-monthly-static-output-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Figure 1. Monthly distribution of daily PM2.5 monitor-day concentrations in 2024.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-monthly-static>


The Figure shows the monthly distribution of daily PM2.5 concentrations across monitor-day observations. Median PM2.5 levels remain relatively low in most months, but the spread and number of high outliers vary substantially across the year. July shows the most extreme PM2.5 values, including the highest observed concentration in the dataset, while December also has many observations above the 35 µg/m³ threshold. These patterns suggest that high-PM2.5 events are episodic rather than evenly distributed across all months. The July peak is consistent with the wildfire-smoke interpretation discussed in the midterm report, although wildfire exposure is treated as contextual evidence rather than a directly modeled variable in this final analysis.

== Regression Models
<regression-models>
#strong[Table 3. Cross-validation selected hyperparameters for regression models.]

#table(
  columns: (21.74%, 23.19%, 55.07%),
  align: (left,right,left,),
  table.header([Model], [Best CV RMSE], [Best parameters],),
  table.hline(),
  [Random Forest], [3.55], [max\_features=0.6, min\_samples\_leaf=1],
  [XGBoost], [3.437], [learning\_rate=0.08, max\_depth=6],
)
Table 3 shows the hyperparameters selected by cross-validation for the two regression models. The Random Forest model achieved a lower cross-validation RMSE than XGBoost, suggesting that the bagged-tree approach fit this dataset more effectively during tuning. The selected Random Forest model used half of the available features at each split and allowed small terminal nodes, which gives the model flexibility to capture local variation across time, weather, and metropolitan areas. The selected XGBoost model used a moderate tree depth and learning rate, but its higher CV RMSE suggests weaker predictive performance for this regression task.

#strong[Table 4. Regression model performance on the test set.]

#table(
  columns: 4,
  align: (left,right,right,right,),
  table.header([Model], [RMSE], [MAE], [R-squared],),
  table.hline(),
  [Random Forest], [3.295], [2.061], [0.661],
  [XGBoost], [3.306], [2.068], [0.658],
)
Table 4 compares model performance on the held-out test set. Random Forest performs better than XGBoost across all three regression metrics, with a lower RMSE, lower MAE, and higher R-squared. The Random Forest test RMSE of 3.318 µg/m³ means that its daily PM2.5 predictions are typically off by about 3.3 µg/m³. Its R-squared of 0.656 indicates that the model explains about 65.6% of the variation in daily mean PM2.5 in the test data. Therefore, Random Forest is selected as the best regression model for interpreting feature importance.

#figure([
#box(image("report_files/figure-typst/fig-reg-importance-output-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Figure 2. Aggregated feature importance for the best regression model.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-reg-importance>


Figure 2 presents the aggregated feature importance from the best regression model, the Random Forest regressor. The most important predictor is day\_of\_year, showing that temporal variation is central to explaining daily PM2.5 patterns. Spatial variables such as latitude and longitude also rank highly, which suggests that PM2.5 levels vary substantially across geographic regions. Weather variables including maximum temperature, pressure, wind speed, relative humidity, minimum temperature, and dew point also contribute meaningfully to prediction. Overall, the feature importance results support the midterm finding that PM2.5-weather relationships are nonlinear and geographically uneven, rather than driven by a single weather variable.

== High PM2.5 Classification
<high-pm2.5-classification>
High-PM2.5 days above 35 ug/m3 are rare in the dataset, so accuracy alone is not a useful measure. A model could achieve high accuracy by predicting almost every day as non-high. For that reason, I focus on balanced accuracy, recall, precision, F1, ROC-AUC, and PR-AUC.

#strong[Table 5. Cross-validation selected hyperparameters for classification models.]

#table(
  columns: 3,
  align: (left,right,left,),
  table.header([Model], [Best CV F1], [Best parameters],),
  table.hline(),
  [Random Forest], [0.483], [max\_features=0.6, min\_samples\_leaf=5],
  [XGBoost], [0.458], [learning\_rate=0.08, max\_depth=4],
)
Table 5 shows the cross-validation results for the high-PM2.5 classification models. Random Forest achieves a higher cross-validation F1 score than XGBoost, suggesting that it performed better during tuning when precision and recall were balanced together. However, because high-PM2.5 days are rare, the final test-set comparison is more important for evaluating whether the model can actually identify high-pollution events.

#strong[Table 6. Classification model performance for PM2.5 greater than 35 ug/m3.]

#table(
  columns: (11.11%, 9.63%, 17.04%, 8.89%, 15.56%, 9.63%, 7.41%, 5.19%, 8.15%, 7.41%),
  align: (left,right,right,right,right,right,right,right,right,right,),
  table.header([Model], [Threshold], [Predicted positives], [Accuracy], [Balanced accuracy], [Precision], [Recall], [F1], [ROC-AUC], [PR-AUC],),
  table.hline(),
  [XGBoost], [0.501], [17], [0.996], [0.749], [0.647], [0.5], [0.564], [0.965], [0.541],
  [Random Forest], [0.5], [21], [0.995], [0.772], [0.571], [0.545], [0.558], [0.991], [0.561],
)
Table 6 compares the two classifiers on the held-out test set. Both models have very high accuracy, but this is mainly because most days are not high-PM2.5 days. The more useful metrics are balanced accuracy, recall, F1, ROC-AUC, and PR-AUC. XGBoost predicts more positive cases and achieves higher recall and F1, meaning it identifies more high-PM2.5 events than Random Forest. Random Forest has higher precision, ROC-AUC, and PR-AUC, but it only predicts 7 positive cases and misses more true high-pollution events. Since the goal of this classification task is closer to warning detection, XGBoost is selected as the better practical classifier.

#figure([
#box(image("report_files/figure-typst/fig-confusion-output-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Figure 3. Confusion matrix for the best high-PM2.5 classifier on the test set.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-confusion>


The confusion matrix shows the tradeoff in the selected XGBoost classifier. The model correctly identifies 12 high-PM2.5 observations, while missing 10 high-PM2.5 observations. It also produces 9 false positives among the non-high observations. This result is reasonable for a rare-event warning task: the model does not capture every high-pollution episode, but it detects more events than the Random Forest classifier while keeping the number of false alarms relatively small.

#figure([
#box(image("report_files/figure-typst/fig-clf-importance-output-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Figure 4. Aggregated feature importance for the best high-PM2.5 classifier.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-clf-importance>


Figure 4 shows that the most important predictors for high-PM2.5 classification are spatial and seasonal variables. cbsa\_name, season, state\_name, and longitude have the largest importance values, suggesting that high-pollution events are strongly shaped by where and when they occur. Weather variables such as precipitation, temperature, and wind also contribute, but they are less dominant than location and season. This supports the interpretation that high PM2.5 episodes are not explained by a single weather factor alone; instead, they reflect interactions between geography, seasonality, and meteorological conditions.

Overall, the classification results should be interpreted as a high-pollution warning task rather than a balanced everyday classification problem. XGBoost is useful here because class weighting and probability threshold adjustment improve recall for rare high-PM2.5 events. The tradeoff is that the model may produce some false positives, which is expected when the goal is to identify rare hazardous episodes rather than simply maximize overall accuracy.

The full interactive versions of the spatial and weather figures are available on the #link("visualizations.html")[interactive visualizations page];.

= Conclusions and Limitations
<conclusions-and-limitations>
== Conclusions
<conclusions>
This project shows that daily PM2.5 variation is shaped by a combination of location, season, and weather conditions. The descriptive results show clear spatial differences across metropolitan areas, with some regions having higher average PM2.5 and more high-pollution monitor-days than others. The monthly distribution also suggests that extreme PM2.5 events are not evenly distributed throughout the year, but instead appear more strongly in specific periods such as July and winter months.

The modeling results support the idea that PM2.5 prediction requires both environmental and contextual information. Weather variables such as temperature, precipitation, wind, humidity, and pressure contribute to prediction, but location and time variables are also important. This suggests that PM2.5 is not driven by one single weather factor. Instead, pollution levels reflect interactions between geography, seasonality, and meteorological conditions.

For continuous PM2.5 prediction, the Random Forest model performs better than XGBoost on the test set, with lower prediction error and higher R-squared. For high-PM2.5 classification, XGBoost is more useful as a warning-oriented model because it identifies more rare high-pollution events. Overall, the project shows that tree-based machine learning models can provide useful predictive summaries of PM2.5 patterns, but the results should be interpreted as predictive associations rather than causal explanations.

== Limitations
<limitations>
- First, the train-test split is based on a random split of monitor-day observations. This is useful for measuring general predictive performance, but it is not the strictest test of generalization. Since observations from the same monitor, city, or season can appear in both the training and testing sets, the model may partially benefit from repeated spatial or temporal patterns. A more rigorous future approach would use grouped splitting by monitor or city, or time-based splitting where earlier months are used for training and later months are used for testing.

- Second, the high-PM2.5 classification task is highly imbalanced. The threshold of 35 µg/m³ is relatively high, so most observations are classified as non-high days. Because of this, accuracy can look very high even when the model does not identify many true high-pollution events. This is why balanced accuracy, recall, F1, ROC-AUC, and PR-AUC are more informative than accuracy alone.

- Third, the 35 µg/m³ threshold is useful for defining extreme PM2.5 days, but it may be too strict for some metropolitan areas where daily PM2.5 rarely reaches that level. As a result, the classification model is mainly detecting rare pollution spikes rather than more moderate but still meaningful pollution variation. Future work could test alternative thresholds or use multi-class air-quality categories.

- Fourth, wildfire smoke is discussed as a possible explanation for some summer PM2.5 peaks, especially the July outliers, but wildfire exposure is not directly measured in the model. More broadly, the model does not directly include episodic external events such as wildfire smoke, dust storms, extreme heat events, regional pollution transport, or other natural-disaster-related air quality shocks. Therefore, these factors should be treated as contextual interpretations rather than causal variables. Future work could add smoke plume data, fire counts, satellite aerosol measurements, dust event indicators, extreme-weather indicators, or distance-to-fire variables to better capture these short-term pollution episodes.

- Fifth, NOAA temperature and precipitation variables are attached at the broader metropolitan level, while PM2.5 is measured at individual monitoring sites. This mismatch may miss local microclimate differences near specific monitors. More localized weather station matching or spatial interpolation could improve the precision of the weather variables.

- Finally, the analysis only uses data from 2024. One year of data is enough for a course project, but it may not fully represent longer-term PM2.5 patterns. Future work could extend the dataset across multiple years to test whether the same spatial, seasonal, and weather relationships remain stable over time.
