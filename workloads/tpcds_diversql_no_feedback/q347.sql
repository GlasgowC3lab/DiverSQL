WITH filtered_sales AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cp.cp_catalog_page_id,
        cp.cp_description,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND regexp_like(cp.cp_description, '(?i)care')
      AND cp.cp_catalog_page_id LIKE 'AAAAAAA%'
),
aggregated AS (
    SELECT
        cp_catalog_page_id,
        regexp_extract(cp_description, '^([^,]+)', 1) AS first_word,
        ib_lower_bound,
        ib_upper_bound,
        SUM(cs_net_profit) AS total_profit
    FROM filtered_sales
    GROUP BY cp_catalog_page_id, cp_description, ib_lower_bound, ib_upper_bound
    HAVING SUM(cs_net_profit) > 5000
)
SELECT
    cp_catalog_page_id,
    first_word,
    ib_lower_bound,
    ib_upper_bound,
    total_profit,
    RANK() OVER (PARTITION BY ib_lower_bound, ib_upper_bound ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 50
