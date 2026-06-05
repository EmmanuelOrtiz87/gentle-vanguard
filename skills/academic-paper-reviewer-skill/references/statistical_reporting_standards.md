# Statistical Reporting Standards — Statistical Reporting Standards & APA 7.0 Format Quick Reference

This document defines the complete review standards for statistical reporting in quantitative
research. `methodology_reviewer_agent` uses this document as the primary reference in Step 4a
(Statistical Reporting Adequacy).

---

## 1. Universal Statistical Reporting Checklist

All quantitative research papers **must** report the following items. Check each item during review:

### 1.1 Descriptive Statistics

| Item                              | Standard                                           | Common Omission                                                 |
| --------------------------------- | -------------------------------------------------- | --------------------------------------------------------------- |
| Mean (_M_)                        | Must be reported for all continuous variables      | Only overall reported, not by group                             |
| Standard deviation (_SD_)         | Must appear paired with the mean                   | Standard error (_SE_) used incorrectly in place of SD           |
| Sample size (_N_ / _n_)           | Both total and group sample sizes must be reported | Sample attrition during analysis unexplained                    |
| Range                             | Report Min-Max or interquartile range              | Completely absent, unable to judge distribution characteristics |
| Categorical variable distribution | Report frequency (_f_) and percentage (%)          | Only percentage reported, missing raw frequency                 |

### 1.2 Effect Size

| Item                      | Standard                                                                                      | Common Omission                                |
| ------------------------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| Reporting obligation      | **All statistical tests must be accompanied by effect sizes** — APA 7.0 mandatory requirement | Only _p_-value reported, no effect size        |
| Select appropriate metric | Choose effect size metric corresponding to the analysis method (see Section 2)                | Inappropriate effect size metric used          |
| Interpretation            | Must provide Cohen's conventional benchmarks or field-specific benchmarks                     | Numbers reported but magnitude not interpreted |

**Common Effect Size Metrics Quick Reference:**

| Analysis Method | Effect Size Metric       | Small/Medium/Large (Cohen's Convention) |
| --------------- | ------------------------ | --------------------------------------- |
| _t_-test        | Cohen's _d_              | 0.2 / 0.5 / 0.8                         |
| ANOVA           | _eta_-squared            | .01 / .06 / .14                         |
| ANOVA (partial) | partial _eta_-squared    | .01 / .06 / .14                         |
| Correlation     | _r_                      | .10 / .30 / .50                         |
| Regression      | _R_-squared, _f_-squared | _f_-squared: .02 / .15 / .35            |
| Chi-square      | Cramer's _V_, _phi_      | _V_: .10 / .30 / .50 (_df_=1)           |
| Odds Ratio      | OR                       | 1.5 / 2.5 / 4.3 (Rosenthal)             |

### 1.3 Confidence Intervals

| Item           | Standard                                                                 | Common Omission                                                |
| -------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------- |
| CI reporting   | All effect sizes and key estimates **should** report 95% CI              | CI completely absent                                           |
| Format         | 95% CI [lower bound, upper bound]                                        | Inconsistent format or using parentheses instead of brackets   |
| Interpretation | Describe the substantive meaning of the CI, not just statistical meaning | Only checking whether CI includes zero, not interpreting width |

### 1.4 Statistical Significance

| Item                    | Standard                                     | Common Omission                                        |
| ----------------------- | -------------------------------------------- | ------------------------------------------------------ |
| _p_-value format        | Report exact _p_ value (e.g., _p_ = .032)    | Only reporting _p_ < .05 or _p_ > .05                  |
| _p_ < .001              | Can report _p_ < .001 when _p_ is very small | Reporting _p_ = .000 (raw statistical software output) |
| Alpha level             | Declare alpha level a priori                 | Failure to state whether alpha = .05 or another value  |
| Multiple comparisons    | Use Bonferroni, Holm, FDR correction         | Multiple comparisons without any correction            |
| Non-significant results | Must be fully reported; cannot be hidden     | Selectively reporting only significant results         |

### 1.5 Statistical Power

| Item                    | Standard                                                                                | Common Omission                                              |
| ----------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| A priori power analysis | State target power (typically >= .80), assumed effect size, alpha, required sample size | Power analysis completely absent                             |
| Effect size source      | Based on prior research, pilot study, or theoretical expectation                        | Using Cohen's convention without explanation                 |
| Tool                    | Use G\*Power, pwr package, etc.                                                         | Tool not specified                                           |
| Post-hoc power          | Report observed power for non-significant results                                       | Type II error risk not discussed for non-significant results |
| Sensitivity analysis    | Report the minimum detectable effect size given _N_                                     | Sensitivity analysis not conducted                           |

### 1.6 Missing Data Handling

| Item                   | Standard                                                                 | Common Omission                              |
| ---------------------- | ------------------------------------------------------------------------ | -------------------------------------------- |
| Missing data reporting | Report missing data amount and proportion for each variable              | Missing data situation not reported          |
| Missing mechanism      | Discuss MCAR / MAR / MNAR                                                | MCAR assumed without testing                 |
| Handling method        | State the method used: listwise deletion / pairwise deletion / MI / FIML | Not stated or only using listwise deletion   |
| Sensitivity analysis   | Compare result robustness across different missing data handling methods | Only one method used, sensitivity not tested |

### 1.7 Assumption Testing

| Assumption                            | Applicable Analysis         | Testing Method                                      | Common Omission                                           |
| ------------------------------------- | --------------------------- | --------------------------------------------------- | --------------------------------------------------------- |
| Normality                             | _t_-test, ANOVA, regression | Shapiro-Wilk / K-S / Q-Q plot / skewness & kurtosis | Completely untested or only invoking CLT                  |
| Homogeneity of variance               | Independent _t_-test, ANOVA | Levene's test                                       | Not reported or alternative method not used when violated |
| Linearity                             | Regression, correlation     | Residual plot / scatter plot                        | Linearity assumed without testing                         |
| Independence                          | Most parametric tests       | Durbin-Watson / research design explanation         | Nested data not handled                                   |
| Multicollinearity                     | Multiple regression         | VIF, tolerance, correlation matrix                  | VIF not reported or reported but not addressed            |
| Residual normality / homoscedasticity | Regression                  | Residual plot, Breusch-Pagan                        | Residuals not checked after model fitting                 |

---

## 2. Method-Specific Checklists

### 2.1 _t_-test (Independent / Paired Samples)

| Check Item            | Description                                                                             |
| --------------------- | --------------------------------------------------------------------------------------- |
| Report _t_ statistic  | _t_(df) = X.XX, _p_ = .XXX                                                              |
| Independent vs paired | Correct selection? Paired designs need to report pairing logic                          |
| Effect size           | Cohen's _d_ (independent) or _d_\_z (paired)                                            |
| Assumption testing    | Normality (important for small samples), homogeneity of variance (independent _t_-test) |
| Welch's _t_-test      | Is Welch correction used when variances are unequal?                                    |
| Directionality        | Is one-tailed vs two-tailed supported by a priori theoretical basis?                    |

### 2.2 ANOVA (One-Way / Factorial / Repeated Measures)

| Check Item            | Description                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------ |
| Report _F_ statistic  | _F_(df1, df2) = X.XX, _p_ = .XXX                                                                 |
| Effect size           | _eta_-squared, partial _eta_-squared, or _omega_-squared                                         |
| Post-hoc comparisons  | When main effect is significant, are post-hoc tests done (Tukey / Bonferroni / Games-Howell)?    |
| Interaction effects   | In factorial designs, are interactions interpreted? Are simple effects tested?                   |
| Sphericity assumption | For repeated measures, is Mauchly's test reported + Greenhouse-Geisser / Huynh-Feldt correction? |
| Assumption testing    | Normality, homogeneity of variance (Levene's), independence of between-group observations        |
| Unequal group sizes   | When group sizes differ substantially, is Type III SS used?                                      |

### 2.3 Regression Analysis (Linear / Logistic)

#### Linear Regression

| Check Item           | Description                                                   |
| -------------------- | ------------------------------------------------------------- |
| Model summary        | _R_-squared, adjusted _R_-squared, _F_ test for model         |
| Coefficient table    | _B_, _SE_, _beta_, _t_, _p_, 95% CI for _B_                   |
| Multicollinearity    | VIF (< 5 or < 10 depending on field convention), tolerance    |
| Residual diagnostics | Normality, homoscedasticity, linearity, outliers (Cook's _D_) |
| Variable selection   | Rationale for enter vs stepwise method                        |
| Effect size          | _R_-squared, _f_-squared, Cohen's _f_-squared                 |

#### Logistic Regression

| Check Item              | Description                                                                                                        |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Model fit               | Hosmer-Lemeshow / chi-squared / -2LL / Nagelkerke _R_-squared                                                      |
| Coefficient reporting   | _B_, _SE_, Wald, OR, 95% CI for OR                                                                                 |
| Classification accuracy | Classification table, sensitivity, specificity, AUC/ROC                                                            |
| Assumptions             | Independence of observations, linearity in the logit (linear relationship between continuous predictors and logit) |
| Sample size             | At least 10-20 events per predictor variable (EPV rule)                                                            |

### 2.4 Structural Equation Modeling (SEM)

| Check Item               | Standard                                                                                     |
| ------------------------ | -------------------------------------------------------------------------------------------- |
| Sample size              | Typically >= 200; or 5-10 times the number of estimated parameters                           |
| Model fit indices        | **Must report multiple indices simultaneously** (at least 4)                                 |
| CFI / TLI                | >= .95 (good); >= .90 (acceptable)                                                           |
| RMSEA                    | <= .06 (good); <= .08 (acceptable); must report 90% CI                                       |
| SRMR                     | <= .08                                                                                       |
| chi-squared/df           | <= 3 (some scholars suggest <= 2)                                                            |
| Factor loadings          | Standardized >= .50 (ideal >= .70)                                                           |
| Measurement model        | CFA before SEM (two-step approach) — Anderson & Gerbing (1988)                               |
| Reliability and validity | CR >= .70, AVE >= .50, discriminant validity (Fornell-Larcker / HTMT)                        |
| Modification indices     | When using modification indices, must have theoretical support                               |
| Normality                | Multivariate normality (Mardia's coefficient); when violated, use robust ML or bootstrapping |

### 2.5 Hierarchical Linear Modeling (HLM / MLM)

| Check Item                | Standard                                                                     |
| ------------------------- | ---------------------------------------------------------------------------- |
| Nested structure          | Clearly explain each level (e.g., students -> classes -> schools)            |
| ICC                       | Report Intraclass Correlation Coefficient; ICC > .05 supports using MLM      |
| Random effects            | Report random intercept and (if applicable) random slope variances           |
| Fixed effects             | Report coefficients, _SE_, _t_ / _z_, _p_, CI                                |
| Between-group sample size | Level-2 unit count (typically recommended >= 30)                             |
| Centering                 | Explain whether grand-mean centering or group-mean centering is used and why |
| Model comparison          | Use deviance (-2LL), AIC, BIC to compare nested models                       |
| Effect size               | Pseudo _R_-squared (e.g., Snijders & Bosker's _R_-squared)                   |

### 2.6 Chi-Square Test

| Check Item           | Description                                                                                        |
| -------------------- | -------------------------------------------------------------------------------------------------- |
| Reporting format     | chi-squared(df, _N_ = XX) = X.XX, _p_ = .XXX                                                       |
| Effect size          | Cramer's _V_ (larger than 2x2) or _phi_ (2x2)                                                      |
| Expected frequencies | All cells expected frequency >= 5; if any cell < 5, use Fisher's exact test                        |
| Independence         | Are observations truly independent? (Repeated measures are not suitable for ordinary chi-square)   |
| Residual analysis    | When significant, check standardized residuals to determine which cells contribute to significance |

### 2.7 Non-Parametric Tests

| Check Item            | Description                                                                                  |
| --------------------- | -------------------------------------------------------------------------------------------- |
| Justification for use | Clearly explain why parametric tests are not used (e.g., normality violation, ordinal scale) |
| Method selection      | Mann-Whitney _U_ / Wilcoxon / Kruskal-Wallis / Friedman — is the correct test matched        |
| Effect size           | _r_ = _Z_ / sqrt(_N_) (Mann-Whitney); _W_ (Kendall's)                                        |
| Reporting format      | Report test statistic, _p_-value, effect size                                                |
| Post-hoc comparisons  | After significant Kruskal-Wallis, pairwise comparisons + correction needed                   |

---

## 3. APA 7th Edition Statistical Format Quick Reference

### 3.1 Number Formatting

| Rule                                                   | Correct                 | Incorrect   |
| ------------------------------------------------------ | ----------------------- | ----------- |
| _p_-value no leading zero                              | _p_ = .032              | _p_ = 0.032 |
| Statistics that can exceed 1.0 have leading zero       | _M_ = 0.75              | _M_ = .75   |
| Statistics that cannot exceed 1.0 have no leading zero | _r_ = .45               | _r_ = 0.45  |
| Generally 2 decimal places                             | _M_ = 3.45              | _M_ = 3.4   |
| _p_-value 2-3 decimal places                           | _p_ = .03 or _p_ = .032 | _p_ = .0321 |
| Percentages 0-1 decimal places                         | 45.2%                   | 45.2381%    |

**Statistics that cannot exceed 1.0** (no leading zero): correlation coefficients (_r_, _R_),
proportions (_p_-value), Cramer's _V_, _phi_, _eta_-squared, _R_-squared, _beta_ (standardized
regression coefficient)

**Statistics that can exceed 1.0** (leading zero): _M_, _SD_, _B_ (unstandardized regression
coefficient), Cohen's _d_, _t_, _F_, chi-squared

### 3.2 Statistical Symbol Italicization Rules

| Italic                                           | Non-italic         |
| ------------------------------------------------ | ------------------ |
| _M_, _SD_, _SE_                                  | df                 |
| _N_ (total sample), _n_ (subsample)              | SS, MS             |
| _t_, _F_, _p_, _r_, _R_, _z_                     | OR, CI, VIF        |
| _d_, _f_-squared, _eta_-squared, _omega_-squared | AIC, BIC, CFI, TLI |
| _B_, _beta_                                      | RMSEA, SRMR        |
| _chi_-squared                                    | ICC                |
| _U_, _W_ (non-parametric statistics)             | ANOVA, SEM, HLM    |

### 3.3 Statistical Results Reporting Format Examples

| Analysis Method              | APA Format Example                                                                                |
| ---------------------------- | ------------------------------------------------------------------------------------------------- |
| Independent samples _t_-test | _t_(58) = 2.45, _p_ = .017, _d_ = 0.63, 95% CI [0.12, 1.14]                                       |
| Paired samples _t_-test      | _t_(29) = -3.12, _p_ = .004, _d_\_z = 0.57                                                        |
| One-way ANOVA                | _F_(2, 87) = 4.56, _p_ = .013, partial _eta_-squared = .09                                        |
| Linear regression            | _B_ = 0.34, _SE_ = 0.12, _beta_ = .28, _t_(95) = 2.83, _p_ = .006, 95% CI [0.10, 0.58]            |
| Logistic regression          | _B_ = 1.24, _SE_ = 0.45, Wald = 7.59, _p_ = .006, OR = 3.46, 95% CI [1.43, 8.37]                  |
| Chi-square                   | chi-squared(2, _N_ = 150) = 8.34, _p_ = .015, _V_ = .24                                           |
| Mann-Whitney                 | _U_ = 245.00, _z_ = -2.31, _p_ = .021, _r_ = .29                                                  |
| SEM fit                      | chi-squared(52) = 78.34, _p_ = .011, CFI = .97, TLI = .96, RMSEA = .045 [.018, .068], SRMR = .038 |
| HLM fixed effects            | _gamma_\_10 = 0.45, _SE_ = 0.15, _t_(28) = 3.00, _p_ = .006                                       |

### 3.4 Table Format Standards

| Rule             | Description                                                                                                  |
| ---------------- | ------------------------------------------------------------------------------------------------------------ |
| Three-line table | APA tables have only three horizontal lines (above header, below header, bottom of table), no vertical lines |
| Table numbering  | Table 1, Table 2... (bold), title on the line below the number (italic)                                      |
| Note levels      | General note (Note.) -> Specific note (superscript a, b) -> Significance (_p_ < .05, \*_p_ < .01)            |
| Asterisks        | \*_p_ < .05. \*\*_p_ < .01. \*\*\*_p_ < .001.                                                                |
| Alignment        | Numbers right-aligned, decimal points aligned                                                                |

---

## 4. Statistical Red Flags

The following patterns during review should raise red flags, requiring further investigation or
author clarification:

### 4.1 P-hacking Indicators

| Red Flag                | Description                                                             | Severity |
| ----------------------- | ----------------------------------------------------------------------- | -------- |
| Many _p_ near .05       | Multiple results with _p_ concentrated in the .04-.05 range             | HIGH     |
| Selective reporting     | Only significant results reported, non-significant ones disappeared     | HIGH     |
| Vague analysis strategy | Analysis strategy not stated a priori, appears exploratory in hindsight | MEDIUM   |
| Unexpected subgroups    | Post-hoc subgroup decomposition to find significant results             | MEDIUM   |
| Flexible sample size    | No pre-defined stopping rule (sequential testing without correction)    | HIGH     |
| "Excluding outliers"    | Large number of outliers excluded with unclear criteria                 | MEDIUM   |

### 4.2 HARKing (Hypothesizing After Results are Known)

| Red Flag                                      | Description                                                                         | Severity |
| --------------------------------------------- | ----------------------------------------------------------------------------------- | -------- |
| Perfect hypothesis-result match               | All hypotheses supported without exception                                          | MEDIUM   |
| Exploratory analysis packaged as confirmatory | Literature review clearly constructed post-hoc                                      | HIGH     |
| Hypothesis directionality change              | Originally predicted positive but result was negative, yet claimed "as expected"    | HIGH     |
| No pre-registration                           | No OSF / AsPredicted pre-registration link provided (not mandatory but recommended) | LOW      |

### 4.3 Missing Effect Sizes and Confidence Intervals

| Red Flag                        | Description                                                        | Severity |
| ------------------------------- | ------------------------------------------------------------------ | -------- |
| No effect sizes reported at all | Conclusions based solely on _p_-values                             | HIGH     |
| CI completely absent            | Cannot judge estimation precision                                  | MEDIUM   |
| Extremely wide CI               | CI spans from small to large effect sizes, imprecise estimation    | MEDIUM   |
| Inconsistent effect sizes       | Reported effect sizes inconsistent with calculations from raw data | HIGH     |

### 4.4 Sample Size Issues

| Red Flag                     | Description                                                      | Severity |
| ---------------------------- | ---------------------------------------------------------------- | -------- |
| No power analysis            | Sample size lacks a priori calculation basis                     | MEDIUM   |
| Sample too small             | In regression analysis, _N_ < 10 x number of predictors          | HIGH     |
| Unexplained sample attrition | Large gap between starting _N_ and final _N_ without explanation | MEDIUM   |
| SEM small sample             | _N_ < 200 without small sample correction                        | MEDIUM   |
| HLM Level-2 insufficient     | Level-2 units < 30                                               | MEDIUM   |

### 4.5 Uncorrected Multiple Comparisons

| Red Flag                            | Description                                                                                  | Severity |
| ----------------------------------- | -------------------------------------------------------------------------------------------- | -------- |
| Multiple _t_-tests instead of ANOVA | 3+ group comparisons using multiple _t_-tests                                                | HIGH     |
| No post-hoc after ANOVA             | Main effect significant but claiming group differences without post-hoc tests                | MEDIUM   |
| Multiple DVs uncorrected            | Multiple dependent variables tested separately on the same dataset without Bonferroni or FDR | MEDIUM   |
| Multiple model comparisons          | Trying multiple models but only reporting "the best one"                                     | HIGH     |

### 4.6 Assumption Violation

| Red Flag                             | Description                                                         | Severity |
| ------------------------------------ | ------------------------------------------------------------------- | -------- |
| Assumption testing completely absent | Skipping normality/homogeneity/linearity tests                      | MEDIUM   |
| Violations not addressed             | Violations reported but original analysis still used                | HIGH     |
| CLT as excuse                        | "Because _N_ > 30, normality can be ignored" without actual testing | LOW      |
| Excessive VIF                        | VIF > 10 but no action taken                                        | HIGH     |

### 4.7 Other Red Flags

| Red Flag                        | Description                                                                     | Severity |
| ------------------------------- | ------------------------------------------------------------------------------- | -------- |
| _p_ = .000                      | Raw statistical software output, should be _p_ < .001                           | LOW      |
| df inconsistent with _N_        | _N_ derived from degrees of freedom doesn't match reported _N_                  | HIGH     |
| Inconsistent table numbers      | Text narrative contradicts table values                                         | HIGH     |
| Statistical software not stated | Not reporting SPSS / R / Stata / Mplus and version                              | LOW      |
| Causal language                 | Non-experimental designs (correlational/survey) using causal inference language | MEDIUM   |

---

## 5. Common Statistical Methods in Higher Education Research

Higher education research papers frequently involve the following topics and corresponding analysis
methods. This table can be referenced during review to judge whether method selection is
appropriate.

### 5.1 Recommended Methods by Research Question Type

| Research Question Type                                     | Recommended Method                             | Description                                                    |
| ---------------------------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------- |
| Two-group comparison (e.g., experimental vs control)       | Independent samples _t_-test / Mann-Whitney    | Depending on data normality                                    |
| Multi-group comparison (e.g., different institution types) | ANOVA / Kruskal-Wallis                         | Mean comparison for 3+ groups                                  |
| Pre-post comparison                                        | Paired _t_-test / Wilcoxon                     | Change within the same group                                   |
| Predictive analysis (continuous DV)                        | Multiple regression                            | Multiple predictors' effects on continuous outcome             |
| Predictive analysis (binary DV)                            | Logistic regression                            | E.g., graduation/dropout, pass/fail                            |
| Nested data (students -> schools)                          | HLM / MLM                                      | Higher education data naturally has nested structure           |
| Latent constructs and path analysis                        | SEM / CFA                                      | Measuring unobservable constructs (e.g., teaching quality)     |
| Scale reliability and validity                             | EFA -> CFA                                     | Scale development or validation                                |
| Categorical variable association                           | Chi-square / Fisher's exact                    | Cross-tabulation analysis                                      |
| Longitudinal data                                          | Growth curve models / Latent growth models     | Tracking student trajectories over multiple years              |
| Large-scale datasets                                       | Weighted analysis / sampling design correction | Accounting for sampling design when using national survey data |

### 5.2 Special Considerations for Higher Education Research

| Consideration        | Description                                                                                                                                                     |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Nested structure** | Higher education data almost always has nesting (students -> departments -> institutions); ignoring it underestimates standard errors and inflates Type I error |
| **Sampling design**  | When using national databases (e.g., MOE statistics, public higher education data), must account for sampling weights and clustering                            |
| **Selection bias**   | Students self-select into departments/institutions, not randomly assigned; consider propensity score matching or Heckman correction                             |
| **Ceiling effects**  | Satisfaction surveys often show extreme skewness; need to check and consider Tobit model or non-parametric methods                                              |
| **Small population** | Taiwan has a limited number of universities (~150); census surveys are not appropriate for inferential statistics (census, not sample)                          |
| **Time series**      | Analyzing multi-year enrollment trends requires considering autocorrelation                                                                                     |
| **Multiple roles**   | Same faculty completing multiple surveys (e.g., teaching evaluations) -> observations not independent                                                           |

---

## 6. Statistical Reporting Completeness Scoring Standards

`methodology_reviewer_agent` uses the following standards to assess statistical reporting
completeness:

### Scoring Dimensions and Weights

| Dimension                              | Weight | Full Score Criteria                             |
| -------------------------------------- | ------ | ----------------------------------------------- |
| A. Descriptive statistics completeness | 15%    | M, SD, N, Range all present                     |
| B. Effect size reporting               | 20%    | All tests accompanied by effect sizes           |
| C. Confidence interval reporting       | 15%    | Key estimates include CI                        |
| D. Assumption testing reporting        | 15%    | All statistical assumptions tested              |
| E. Statistical power                   | 10%    | Complete a priori power analysis                |
| F. Missing data handling               | 10%    | Missing data amounts + handling method reported |
| G. APA format correctness              | 10%    | Symbols, decimals, tables compliant             |
| H. No red flag indicators              | 5%     | No red flags from Section 4 detected            |

### Scoring Levels

| Level             | Score  | Description                                                                                      |
| ----------------- | ------ | ------------------------------------------------------------------------------------------------ |
| Exemplary         | 90-100 | Statistical reporting is exemplary, all items complete and correctly formatted                   |
| Adequate          | 70-89  | Major items complete, minor omissions that don't affect conclusion credibility                   |
| Needs Improvement | 50-69  | Significant omissions (e.g., missing effect sizes or assumption testing), supplementation needed |
| Inadequate        | 30-49  | Multiple items missing, statistical reporting insufficient to support conclusions                |
| Unacceptable      | 0-29   | Severely insufficient statistical reporting, major rewrite needed                                |

---

## 7. Quick Reference: Recommended Review Sequence

Methodology reviewer should follow this sequence when reviewing statistical reporting:

```
Step 1: Confirm research question -> analysis method correspondence is reasonable (Section 5)
Step 2: Check whether assumption testing is reported (Section 1.7)
Step 3: Check universal checklist item by item (Sections 1.1-1.6)
Step 4: Consult method-specific checklist (Section 2)
Step 5: Scan red flag list (Section 4)
Step 6: Verify APA formatting (Section 3)
Step 7: Produce completeness score (Section 6)
```
