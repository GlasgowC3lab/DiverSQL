WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_formulation,
        i_brand,
        i_category,
        regexp_extract(i_formulation, '([0-9]+)', 1) AS digits_extracted,
        CONCAT(i_brand, ' ', i_category) AS brand_category
    FROM item
    WHERE regexp_like(i_formulation, 'steel')
      AND i_product_name LIKE '%Gold%'
),
agg_returns AS (
    SELECT
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        fi.brand_category,
        fi.digits_extracted,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_ship_cost) AS avg_ship_cost
    FROM reason r
    RIGHT OUTER JOIN web_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN filtered_items fi
        ON wr.wr_item_sk = fi.i_item_sk
    LEFT JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        fi.brand_category,
        fi.digits_extracted
)
SELECT
    r_reason_desc,
    ib_lower_bound,
    ib_upper_bound,
    brand_category,
    digits_extracted,
    total_returns,
    total_return_amount,
    avg_ship_cost,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM agg_returns
ORDER BY total_return_amount DESC
LIMIT 100
