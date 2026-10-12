WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity,
        MAX(cs.cs_promo_sk) AS promo_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk, cs.cs_bill_customer_sk, cs.cs_item_sk

    UNION ALL

    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        SUM(ws.ws_net_paid),
        SUM(ws.ws_net_profit),
        SUM(ws.ws_quantity),
        MAX(ws.ws_promo_sk)
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_bill_customer_sk, ws.ws_item_sk
),

returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_returning_customer_sk AS customer_sk,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS return_quantity
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_returning_customer_sk, cr.cr_item_sk

    UNION ALL

    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returning_customer_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt),
        SUM(wr.wr_net_loss),
        SUM(wr.wr_return_quantity)
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_returning_customer_sk, wr.wr_item_sk
),

combined AS (
    SELECT
        s.date_sk,
        s.customer_sk,
        s.item_sk,
        s.net_paid,
        s.net_profit,
        s.quantity,
        r.return_amount,
        r.net_loss,
        r.return_quantity,
        COALESCE(s.promo_sk, 0) AS promo_sk,
        COALESCE(r.return_amount, 0.0) AS return_amount_coalesce,
        COALESCE(r.net_loss, 0.0) AS net_loss_coalesce
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.date_sk = r.date_sk
        AND s.customer_sk = r.customer_sk
        AND s.item_sk = r.item_sk
),

detailed AS (
    SELECT
        c.date_sk,
        d.d_date AS sale_date,
        c.customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        CONCAT(cu.c_first_name, ' ', cu.c_last_name) AS customer_full_name,
        c.item_sk,
        i.i_product_name,
        i.i_brand,
        c.quantity,
        c.net_paid,
        c.net_profit,
        c.return_amount,
        c.net_loss,
        c.return_quantity,
        CASE
            WHEN c.net_profit > 0 THEN 'PROFITABLE'
            WHEN c.net_profit < 0 THEN 'LOSS'
            ELSE 'BREAKEVEN'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY c.customer_sk ORDER BY d.d_date DESC) AS rn_customer_latest_sale,
        SUM(c.net_paid) OVER (
            PARTITION BY c.customer_sk
            ORDER BY d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_paid,
        AVG(c.net_profit) OVER (PARTITION BY i.i_brand) AS avg_brand_profit,
        CASE WHEN c.return_quantity IS NULL THEN 0 ELSE c.return_quantity END AS returned_qty,
        COALESCE(c.return_amount, 0) / NULLIF(c.net_paid, 0) AS return_rate,
        (c.net_paid - COALESCE(c.return_amount, 0)) / NULLIF(c.net_profit + COALESCE(c.net_loss, 0), 0) AS profit_efficiency
    FROM combined c
    LEFT JOIN date_dim d ON c.date_sk = d.d_date_sk
    LEFT JOIN customer cu ON c.customer_sk = cu.c_customer_sk
    LEFT JOIN item i ON c.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
),

brand_best AS (
    SELECT
        d_year,
        i_brand,
        total_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS brand_rank
    FROM (
        SELECT
            d.d_year,
            i.i_brand,
            SUM(s.cs_ext_sales_price) AS total_sales
        FROM catalog_sales s
        JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON s.cs_item_sk = i.i_item_sk
        GROUP BY d.d_year, i.i_brand
    ) b
)

SELECT
    d.customer_full_name,
    d.sale_date,
    d.i_product_name,
    d.i_brand,
    d.quantity,
    d.net_paid,
    d.net_profit,
    d.return_amount,
    d.return_quantity,
    d.profit_category,
    d.rn_customer_latest_sale,
    d.cumulative_paid,
    d.avg_brand_profit,
    d.returned_qty,
    ROUND(d.return_rate * 100, 2) AS return_rate_percent,
    ROUND(d.profit_efficiency, 4) AS profit_efficiency_ratio,
    COALESCE(bb.i_brand, 'UNKNOWN') AS top_brand_this_year,
    COALESCE(bb.total_sales, 0) AS top_brand_sales,
    CASE WHEN bb.brand_rank = 1 THEN 'TOP_BRAND' ELSE NULL END AS top_brand_flag
FROM detailed d
LEFT JOIN (
    SELECT d_year, i_brand, total_sales, brand_rank
    FROM brand_best
    WHERE brand_rank = 1
) bb
    ON EXTRACT(year FROM d.sale_date) = bb.d_year
    AND d.i_brand = bb.i_brand
WHERE d.rn_customer_latest_sale = 1
ORDER BY d.cumulative_paid DESC
LIMIT 100
