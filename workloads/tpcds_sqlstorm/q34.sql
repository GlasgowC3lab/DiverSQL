WITH cat_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
),
cat_sales_agg AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_category,
        SUM(cs.cs_net_paid) AS total_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        COUNT(*) AS orders
    FROM cat_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, p.p_promo_id, cd.cd_gender, cd.cd_marital_status, i.i_category
),
cat_returns_agg AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN cat_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, p.p_promo_id, cd.cd_gender, cd.cd_marital_status, i.i_category
),
store_sales_agg AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(*) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, p.p_promo_id, cd.cd_gender, cd.cd_marital_status, i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_return,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, p.p_promo_id, cd.cd_gender, cd.cd_marital_status, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_category,
        SUM(ws.ws_net_paid) AS total_paid,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        COUNT(*) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, p.p_promo_id, cd.cd_gender, cd.cd_marital_status, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_category,
        SUM(wr.wr_return_amt) AS total_return,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, p.p_promo_id, cd.cd_gender, cd.cd_marital_status, i.i_category
),
combined_sales AS (
    SELECT d_year, p_promo_id, cd_gender, cd_marital_status, i_category, total_paid, total_profit, distinct_customers, orders FROM cat_sales_agg
    UNION ALL
    SELECT d_year, p_promo_id, cd_gender, cd_marital_status, i_category, total_paid, total_profit, distinct_customers, orders FROM store_sales_agg
    UNION ALL
    SELECT d_year, p_promo_id, cd_gender, cd_marital_status, i_category, total_paid, total_profit, distinct_customers, orders FROM web_sales_agg
),
combined_returns AS (
    SELECT d_year, p_promo_id, cd_gender, cd_marital_status, i_category, total_return, total_loss, return_cnt FROM cat_returns_agg
    UNION ALL
    SELECT d_year, p_promo_id, cd_gender, cd_marital_status, i_category, total_return, total_loss, return_cnt FROM store_returns_agg
    UNION ALL
    SELECT d_year, p_promo_id, cd_gender, cd_marital_status, i_category, total_return, total_loss, return_cnt FROM web_returns_agg
),
final_agg AS (
    SELECT
        s.d_year,
        s.p_promo_id,
        s.cd_gender,
        s.cd_marital_status,
        s.i_category,
        s.total_paid,
        s.total_profit,
        COALESCE(r.total_return, 0) AS total_return,
        COALESCE(r.total_loss, 0) AS total_loss,
        s.distinct_customers,
        s.orders
    FROM combined_sales s
    LEFT JOIN combined_returns r
        ON s.d_year = r.d_year
       AND s.p_promo_id = r.p_promo_id
       AND s.cd_gender = r.cd_gender
       AND s.cd_marital_status = r.cd_marital_status
       AND s.i_category = r.i_category
)
SELECT
    d_year,
    p_promo_id,
    cd_gender,
    cd_marital_status,
    i_category,
    year_total_paid,
    year_total_profit,
    year_total_return,
    year_total_loss,
    year_distinct_customers,
    year_orders,
    year_profit_margin,
    profit_rank
FROM (
    SELECT
        d_year,
        p_promo_id,
        cd_gender,
        cd_marital_status,
        i_category,
        year_total_paid,
        year_total_profit,
        year_total_return,
        year_total_loss,
        year_distinct_customers,
        year_orders,
        year_profit_margin,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_profit DESC) AS profit_rank
    FROM (
        SELECT
            d_year,
            p_promo_id,
            cd_gender,
            cd_marital_status,
            i_category,
            SUM(total_paid) AS year_total_paid,
            SUM(total_profit) AS year_total_profit,
            SUM(total_return) AS year_total_return,
            SUM(total_loss) AS year_total_loss,
            SUM(distinct_customers) AS year_distinct_customers,
            SUM(orders) AS year_orders,
            SUM(total_profit - total_loss) AS net_profit,
            SUM(total_paid - total_return) AS net_revenue,
            SUM(total_profit - total_loss) / NULLIF(SUM(total_paid - total_return), 0) AS year_profit_margin
        FROM final_agg
        GROUP BY d_year, p_promo_id, cd_gender, cd_marital_status, i_category
        HAVING SUM(total_profit - total_loss) > 0
    ) agg
) ranked
WHERE profit_rank <= 50
ORDER BY d_year, profit_rank
