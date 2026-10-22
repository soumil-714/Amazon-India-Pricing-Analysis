# Data decision log

1. Dropped 114 repeat rows; kept highest Rating_count per Product_id (same product scraped multiple times)
2. B096MSW6CT had conflicting actual prices (999 vs 1899); kept 999 (majority of scrapes)
3. Stated discount matches recomputed discount (max gap 0.005, rounding only); no inflated discounts found
4. Rating '|' on B08L12N5H1 set to null; 2 missing Rating_count left null and flagged, not imputed
5. Discount converted from fraction to percentage (discount_pct)
6. Category split into main/sub/leaf
7. Review columns: only User_Id/Review_Id split reliably; Review_Content kept at product level, titles used only where counts match
8. Same review appeared under multiple products (variants): reviews deduplicated to one row per review_id (9,265), bridge table keeps product links (10,598)
9. Variant groups built from shared reviews (1,181 listings from 1,351 products); is_primary_listing used for rating and review-count analysis
10. Categories with 1-2 products grouped into 'Other' for comparisons
11. Price buckets set from quartiles; rating_reliability flag at 100 and 1,000 ratings
12. adj_rating = Bayesian average with C = mean rating, m = median rating count; missing inputs stay null
13. value_score = 50% adj_rating + 30% discount + 20% price vs sub-category median (percentile ranks); weights are a judgment call
14. Repaired mis-encoded characters in product text

## Text analysis

- Only review titles analysed: Review_Content cannot be split into individual reviews reliably
- No per-review star rating exists, so low-rated vs high-rated products (ratings at or below the 15th percentile, 3.8, or at or above the 85th, 4.4; ties make each tier somewhat larger than 15%) are compared
- Sentiment from VADER (English only, rough: misreads mixed titles and typos; Hindi titles score neutral); the listing-level correlation is the headline because ~8 reviews share a product
- Complaint themes from keyword rules, ignoring clearly positive titles (sentiment 0.4+); high-tier counts are small, so ratios are approximate
- Repaired mis-encoded emoji, apostrophes and Hindi text in review titles (CSV and MySQL)

## Sensitivity and flags

- Discount vs rating tested on all products (rho -0.150) and distinct listings (rho -0.163): not driven by variant duplicates
- Adjusted rating tested for m from 100 to 10,000: overall ordering stable (rank corr 0.96+), top-20 membership is not; kept m = median rating count
- value_score tested with four alternative weightings (rank corr 0.88-0.96); reported as tiers plus robust_value_pick (top 50 under all weightings), not exact ranks
- price_premium_flag = price at least 2x leaf-category median (leaf groups of 10+ distinct listings) and adj_rating below the leaf average; low_rating_flag = rating 3.8 or below (3.8 is the 15th-percentile cut-off; ties at 3.8 bring it to about 19% of distinct listings)
- price_premium_flag is a screen for manual review, not a verdict: leaf categories can mix product types (for example mini bag sealers and full sealing machines)
