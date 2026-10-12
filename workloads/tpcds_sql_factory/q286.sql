WITH yearly_item_sales AS (
    SELECT
        cs.cs_item_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_tax) AS total_tax,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_net_paid_inc_tax) AS avg_net_paid_inc_tax
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_year
),
item_inventory AS (
    SELECT
        i.inv_item_sk,
        MAX(i.inv_quantity_on_hand) AS max_quantity_on_hand
    FROM inventory i
    GROUP BY i.inv_item_sk
),
ranked_sales AS (
    SELECT
        yis.cs_item_sk AS item_sk,
        yis.d_year,
        yis.total_net_profit,
        yis.total_quantity,
        yis.total_sales,
        ROUND(yis.total_net_profit / NULLIF(yis.total_sales, 0) * 100, 2) AS profit_margin_pct,
        yis.avg_net_paid_inc_tax,
        ii.max_quantity_on_hand,
        RANK() OVER (PARTITION BY yis.d_year ORDER BY yis.total_net_profit DESC) AS profit_rank,
        SUM(yis.total_sales) OVER (PARTITION BY yis.d_year) AS year_total_sales
    FROM yearly_item_sales yis
    LEFT JOIN item_inventory ii ON yis.cs_item_sk = ii.inv_item_sk
)
SELECT
    d_year,
    item_sk,
    total_net_profit,
    total_quantity,
    total_sales,
    profit_margin_pct,
    avg_net_paid_inc_tax,
    max_quantity_on_hand,
    profit_rank,
    ROUND(total_sales / NULLIF(year_total_sales, 0) * 100, 2) AS sales_share_pct
FROM ranked_sales
WHERE profit_rank <= 4
ORDER BY d_year, profit_rank
