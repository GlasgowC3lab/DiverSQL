WITH cat_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           d.d_year AS sale_year,
           d.d_month_seq AS month_seq,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS discount_amt,
           p.p_cost AS promo_cost,
           cd.cd_gender AS gender
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
), store_sales_agg AS (
    SELECT ss.ss_item_sk AS item_sk,
           d.d_year AS sale_year,
           d.d_month_seq AS month_seq,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_discount_amt AS discount_amt,
           p.p_cost AS promo_cost,
           cd.cd_gender AS gender
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
), web_sales_agg AS (
    SELECT ws.ws_item_sk AS item_sk,
           d.d_year AS sale_year,
           d.d_month_seq AS month_seq,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_ext_discount_amt AS discount_amt,
           p.p_cost AS promo_cost,
           cd.cd_gender AS gender
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
), sales_combined AS (
    SELECT * FROM cat_sales
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
), cat_returns AS (
    SELECT cr.cr_item_sk AS item_sk,
           d.d_year AS sale_year,
           d.d_month_seq AS month_seq,
           cr.cr_return_quantity AS quantity,
           cr.cr_net_loss AS net_loss,
           cd.cd_gender AS gender
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
), store_returns_agg AS (
    SELECT sr.sr_item_sk AS item_sk,
           d.d_year AS sale_year,
           d.d_month_seq AS month_seq,
           sr.sr_return_quantity AS quantity,
           sr.sr_net_loss AS net_loss,
           cd.cd_gender AS gender
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
), web_returns_agg AS (
    SELECT wr.wr_item_sk AS item_sk,
           d.d_year AS sale_year,
           d.d_month_seq AS month_seq,
           wr.wr_return_quantity AS quantity,
           wr.wr_net_loss AS net_loss,
           cd.cd_gender AS gender
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
), returns_combined AS (
    SELECT * FROM cat_returns
    UNION ALL
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
), sales_agg AS (
    SELECT sc.item_sk,
           sc.sale_year,
           sc.month_seq,
           sc.gender,
           SUM(sc.quantity) AS total_quantity,
           SUM(sc.net_paid) AS total_net_paid,
           SUM(sc.net_profit) AS total_net_profit,
           AVG(sc.discount_amt) AS avg_discount,
           SUM(sc.promo_cost) AS total_promo_cost
    FROM sales_combined sc
    GROUP BY sc.item_sk, sc.sale_year, sc.month_seq, sc.gender
), returns_agg AS (
    SELECT rc.item_sk,
           rc.sale_year,
           rc.month_seq,
           rc.gender,
           SUM(rc.quantity) AS total_return_qty,
           SUM(rc.net_loss) AS total_return_loss
    FROM returns_combined rc
    GROUP BY rc.item_sk, rc.sale_year, rc.month_seq, rc.gender
), final_agg AS (
    SELECT s.item_sk,
           s.sale_year,
           s.month_seq,
           s.gender,
           s.total_quantity,
           s.total_net_paid,
           s.total_net_profit,
           s.avg_discount,
           s.total_promo_cost,
           COALESCE(r.total_return_qty, 0) AS total_return_qty,
           COALESCE(r.total_return_loss, 0) AS total_return_loss,
           (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_contribution
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.item_sk = r.item_sk
        AND s.sale_year = r.sale_year
        AND s.month_seq = r.month_seq
        AND s.gender = r.gender
), ranked AS (
    SELECT f.*,
           RANK() OVER (PARTITION BY f.sale_year, f.month_seq, f.gender ORDER BY f.net_contribution DESC) AS profit_rank
    FROM final_agg f
)
SELECT r.sale_year AS year,
       r.month_seq,
       r.gender,
       i.i_item_id,
       i.i_product_name,
       r.total_quantity,
       r.total_net_paid,
       r.total_net_profit,
       r.avg_discount,
       r.total_promo_cost,
       r.total_return_qty,
       r.total_return_loss,
       r.net_contribution,
       r.profit_rank
FROM ranked r
JOIN item i ON r.item_sk = i.i_item_sk
WHERE r.profit_rank <= 5
ORDER BY r.sale_year, r.month_seq, r.gender, r.profit_rank
