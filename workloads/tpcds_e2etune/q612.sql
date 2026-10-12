WITH
store_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy AS month,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2021
    GROUP BY i.i_category, d.d_year, d.d_moy
),
catalog_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy AS month,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2021
    GROUP BY i.i_category, d.d_year, d.d_moy
),
catalog_returns_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy AS month,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2021
    GROUP BY i.i_category, d.d_year, d.d_moy
),
web_returns_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy AS month,
        SUM(wr.wr_net_loss) AS web_return_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2021
    GROUP BY i.i_category, d.d_year, d.d_moy
),
all_keys AS (
    SELECT i_category AS category, d_year AS year, month FROM store_sales_agg
    UNION
    SELECT i_category, d_year, month FROM catalog_sales_agg
    UNION
    SELECT i_category, d_year, month FROM catalog_returns_agg
    UNION
    SELECT i_category, d_year, month FROM web_returns_agg
)
SELECT
    k.category,
    k.year,
    k.month,
    COALESCE(ssa.store_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0) AS total_sales_net_profit,
    COALESCE(cra.catalog_return_loss, 0) + COALESCE(wra.web_return_loss, 0) AS total_return_loss,
    (COALESCE(ssa.store_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0)) -
    (COALESCE(cra.catalog_return_loss, 0) + COALESCE(wra.web_return_loss, 0)) AS net_impact,
    (COALESCE(cra.catalog_return_qty, 0) + COALESCE(wra.web_return_qty, 0)) /
        NULLIF(COALESCE(cra.catalog_return_cnt, 0) + COALESCE(wra.web_return_cnt, 0), 0) AS avg_return_qty_per_return,
    RANK() OVER (
        ORDER BY (COALESCE(ssa.store_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0)) -
                 (COALESCE(cra.catalog_return_loss, 0) + COALESCE(wra.web_return_loss, 0)) DESC
    ) AS net_impact_rank
FROM all_keys k
LEFT JOIN store_sales_agg ssa
    ON k.category = ssa.i_category AND k.year = ssa.d_year AND k.month = ssa.month
LEFT JOIN catalog_sales_agg csa
    ON k.category = csa.i_category AND k.year = csa.d_year AND k.month = csa.month
LEFT JOIN catalog_returns_agg cra
    ON k.category = cra.i_category AND k.year = cra.d_year AND k.month = cra.month
LEFT JOIN web_returns_agg wra
    ON k.category = wra.i_category AND k.year = wra.d_year AND k.month = wra.month
WHERE (COALESCE(ssa.store_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0)) -
      (COALESCE(cra.catalog_return_loss, 0) + COALESCE(wra.web_return_loss, 0)) > 0
ORDER BY net_impact DESC
LIMIT 100
