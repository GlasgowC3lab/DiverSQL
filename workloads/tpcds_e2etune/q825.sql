WITH avg_tax AS (
    SELECT AVG(cc_tax_percentage) AS avg_tax_pct
    FROM call_center
    WHERE cc_market_manager = 'Julius Tran'
)
SELECT
    i.i_category,
    i.i_brand,
    hd.hd_income_band_sk,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS transaction_cnt,
    (SELECT avg_tax_pct FROM avg_tax) AS avg_cc_tax_pct
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
  AND i.i_category IN ('Electronics', 'Furniture')
GROUP BY i.i_category, i.i_brand, hd.hd_income_band_sk
HAVING SUM(ss.ss_ext_sales_price) > 100000
ORDER BY total_profit DESC
LIMIT 50
