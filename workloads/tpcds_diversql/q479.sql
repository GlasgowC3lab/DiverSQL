WITH
    filtered_items AS (
        SELECT
            i_item_sk,
            i_product_name,
            i_brand,
            i_color,
            i_size,
            regexp_extract(i_product_name, '(\\d+)', 1) AS product_code
        FROM tpcds.item
        WHERE regexp_like(i_product_name, '^.*[0-9]{3}.*$')
          AND i_color LIKE 'Red%'
          AND i_size = 'M'
    ),
    catalog_sales_sample AS (
        SELECT *
        FROM tpcds.catalog_sales
        TABLESAMPLE BERNOULLI (10)
    )
SELECT
    ib.ib_income_band_sk            AS income_band_sk,
    fi.i_brand                      AS brand,
    SUM(cs.cs_net_profit)           AS net_amount,
    MAX(lvl.extracted_part)         AS sample_code
FROM catalog_sales_sample cs
JOIN filtered_items fi
     ON cs.cs_item_sk = fi.i_item_sk
JOIN tpcds.household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN LATERAL (
        SELECT regexp_extract(fi.i_product_name, '(\\d+)', 1) AS extracted_part
) lvl ON TRUE
WHERE cs.cs_net_paid_inc_ship_tax > 1000
GROUP BY ib.ib_income_band_sk, fi.i_brand

UNION DISTINCT

SELECT
    ib.ib_income_band_sk            AS income_band_sk,
    fi.i_brand                      AS brand,
    -SUM(sr.sr_net_loss)            AS net_amount,
    MAX(lvl.extracted_part)         AS sample_code
FROM tpcds.store_returns sr
JOIN filtered_items fi
     ON sr.sr_item_sk = fi.i_item_sk
JOIN tpcds.household_demographics hd
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN LATERAL (
        SELECT regexp_extract(fi.i_product_name, '(\\d+)', 1) AS extracted_part
) lvl ON TRUE
WHERE sr.sr_return_quantity > 0
GROUP BY ib.ib_income_band_sk, fi.i_brand

ORDER BY income_band_sk, brand
