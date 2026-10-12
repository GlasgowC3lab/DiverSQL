WITH store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY i.i_item_sk, i.i_brand, hd.hd_income_band_sk
),
catalog_agg AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY i.i_item_sk, i.i_brand, hd.hd_income_band_sk
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        hd.hd_income_band_sk,
        SUM(wr.wr_net_loss) AS returns_net_loss,
        SUM(wr.wr_return_quantity) AS returns_quantity
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY i.i_item_sk, i.i_brand, hd.hd_income_band_sk
)
SELECT
    COALESCE(s.i_brand, c.i_brand, r.i_brand) AS brand,
    COALESCE(s.hd_income_band_sk, c.hd_income_band_sk, r.hd_income_band_sk) AS income_band,
    COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) - COALESCE(r.returns_net_loss, 0) AS total_net_profit,
    COALESCE(s.store_quantity, 0) + COALESCE(c.catalog_quantity, 0) - COALESCE(r.returns_quantity, 0) AS net_quantity_sold,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(s.hd_income_band_sk, c.hd_income_band_sk, r.hd_income_band_sk)
        ORDER BY (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) DESC
    ) AS profit_rank
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.i_item_sk = c.i_item_sk AND s.hd_income_band_sk = c.hd_income_band_sk
FULL OUTER JOIN returns_agg r
    ON COALESCE(s.i_item_sk, c.i_item_sk) = r.i_item_sk
   AND COALESCE(s.hd_income_band_sk, c.hd_income_band_sk) = r.hd_income_band_sk
WHERE (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 10
