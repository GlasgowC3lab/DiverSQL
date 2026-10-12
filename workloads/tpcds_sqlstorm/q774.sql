WITH sales_base AS (
    SELECT
        s.channel,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id,
        i.i_product_name,
        SUM(s.sales_quantity) AS total_quantity,
        SUM(s.sales_net_paid) AS total_net_paid,
        SUM(s.sales_net_profit) AS total_net_profit,
        SUM(s.sales_discount) AS total_discount,
        SUM(s.sales_ext_tax) AS total_tax,
        AVG(s.promo_discount) AS avg_promo_discount
    FROM (
        SELECT
            'store' AS channel,
            ss.ss_sold_date_sk AS sold_date_sk,
            ss.ss_item_sk AS item_sk,
            ss.ss_quantity AS sales_quantity,
            ss.ss_net_paid AS sales_net_paid,
            ss.ss_net_profit AS sales_net_profit,
            ss.ss_ext_discount_amt AS sales_discount,
            ss.ss_ext_tax AS sales_ext_tax,
            p.p_cost AS promo_discount
        FROM store_sales ss
        LEFT JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
           AND ss.ss_item_sk = p.p_item_sk

        UNION ALL

        SELECT
            'catalog' AS channel,
            cs.cs_sold_date_sk AS sold_date_sk,
            cs.cs_item_sk AS item_sk,
            cs.cs_quantity AS sales_quantity,
            cs.cs_net_paid AS sales_net_paid,
            cs.cs_net_profit AS sales_net_profit,
            cs.cs_ext_discount_amt AS sales_discount,
            cs.cs_ext_tax AS sales_ext_tax,
            p.p_cost AS promo_discount
        FROM catalog_sales cs
        LEFT JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
           AND cs.cs_item_sk = p.p_item_sk

        UNION ALL

        SELECT
            'web' AS channel,
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_item_sk AS item_sk,
            ws.ws_quantity AS sales_quantity,
            ws.ws_net_paid AS sales_net_paid,
            ws.ws_net_profit AS sales_net_profit,
            ws.ws_ext_discount_amt AS sales_discount,
            ws.ws_ext_tax AS sales_ext_tax,
            p.p_cost AS promo_discount
        FROM web_sales ws
        LEFT JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
           AND ws.ws_item_sk = p.p_item_sk
    ) s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY
        s.channel,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id,
        i.i_product_name
),
returns_base AS (
    SELECT
        r.channel,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id,
        SUM(r.return_quantity) AS return_quantity,
        SUM(r.return_amount) AS return_amount,
        SUM(r.net_loss) AS return_net_loss
    FROM (
        SELECT
            'store' AS channel,
            sr.sr_returned_date_sk AS return_date_sk,
            sr.sr_item_sk AS item_sk,
            sr.sr_return_quantity AS return_quantity,
            sr.sr_return_amt AS return_amount,
            sr.sr_net_loss AS net_loss
        FROM store_returns sr

        UNION ALL

        SELECT
            'catalog' AS channel,
            cr.cr_returned_date_sk AS return_date_sk,
            cr.cr_item_sk AS item_sk,
            cr.cr_return_quantity AS return_quantity,
            cr.cr_return_amount AS return_amount,
            cr.cr_net_loss AS net_loss
        FROM catalog_returns cr

        UNION ALL

        SELECT
            'web' AS channel,
            wr.wr_returned_date_sk AS return_date_sk,
            wr.wr_item_sk AS item_sk,
            wr.wr_return_quantity AS return_quantity,
            wr.wr_return_amt AS return_amount,
            wr.wr_net_loss AS net_loss
        FROM web_returns wr
    ) r
    JOIN date_dim d ON r.return_date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY
        r.channel,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id
),
combined AS (
    SELECT
        s.channel,
        s.d_year,
        s.d_month_seq,
        s.i_category,
        s.i_class,
        s.i_brand,
        s.i_item_id,
        s.i_product_name,
        s.total_quantity,
        s.total_net_paid,
        s.total_net_profit,
        s.total_discount,
        s.total_tax,
        s.avg_promo_discount,
        COALESCE(r.return_quantity, 0) AS return_quantity,
        COALESCE(r.return_amount, 0) AS return_amount,
        COALESCE(r.return_net_loss, 0) AS return_net_loss,
        s.total_net_profit - COALESCE(r.return_net_loss, 0) AS adjusted_net_profit
    FROM sales_base s
    LEFT JOIN returns_base r
        ON s.channel = r.channel
       AND s.d_year = r.d_year
       AND s.d_month_seq = r.d_month_seq
       AND s.i_category = r.i_category
       AND s.i_class = r.i_class
       AND s.i_brand = r.i_brand
       AND s.i_item_id = r.i_item_id
)
SELECT
    channel,
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    i_item_id,
    i_product_name,
    total_quantity,
    total_net_paid,
    total_net_profit,
    adjusted_net_profit,
    total_discount,
    total_tax,
    avg_promo_discount,
    return_quantity,
    return_amount,
    return_net_loss,
    RANK() OVER (PARTITION BY channel, d_year, i_category ORDER BY adjusted_net_profit DESC) AS profit_rank
FROM combined
WHERE d_year BETWEEN 1999 AND 2002
ORDER BY channel, d_year, i_category, profit_rank
LIMIT 100
