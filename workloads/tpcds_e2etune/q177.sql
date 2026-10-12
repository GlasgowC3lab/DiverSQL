WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY wr.wr_order_number, wr.wr_item_sk
),
site_promo_agg AS (
    SELECT
        s.ws_web_site_sk,
        s.ws_promo_sk,
        ws_site.web_name,
        promo.p_promo_name,
        SUM(s.ws_net_profit) AS total_net_profit,
        SUM(s.ws_ext_sales_price) AS total_sales,
        COALESCE(SUM(r.total_return_amt), 0) AS total_return_amount,
        SUM(s.ws_net_profit) - COALESCE(SUM(r.total_return_amt), 0) AS net_profit_after_returns,
        COUNT(DISTINCT s.ws_order_number) AS num_orders,
        AVG(promo.p_cost) AS avg_promo_cost,
        AVG(s.ws_ext_discount_amt) AS avg_discount_amt
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.ws_order_number = r.wr_order_number
        AND s.ws_item_sk = r.wr_item_sk
    JOIN web_site ws_site ON s.ws_web_site_sk = ws_site.web_site_sk
    JOIN promotion promo ON s.ws_promo_sk = promo.p_promo_sk
    WHERE promo.p_cost > 5000
      AND ws_site.web_country = 'United States'
    GROUP BY s.ws_web_site_sk, s.ws_promo_sk, ws_site.web_name, promo.p_promo_name
    HAVING SUM(s.ws_net_profit) > 100000
)
SELECT
    spa.ws_web_site_sk,
    spa.ws_promo_sk,
    spa.web_name,
    spa.p_promo_name,
    spa.total_net_profit,
    spa.total_sales,
    spa.total_return_amount,
    spa.net_profit_after_returns,
    spa.num_orders,
    spa.avg_promo_cost,
    spa.avg_discount_amt,
    RANK() OVER (PARTITION BY spa.ws_web_site_sk ORDER BY spa.net_profit_after_returns DESC) AS promo_rank
FROM site_promo_agg spa
ORDER BY spa.net_profit_after_returns DESC
LIMIT 20
