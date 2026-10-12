WITH cr_base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_catalog_page_sk,
        cr.cr_order_number,
        d.d_date,
        d.d_year,
        d.d_month_seq
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 50
),
sr_base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_customer_sk AS customer_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_amt > 50
),
full_returns AS (
    SELECT
        COALESCE(cr_base.cr_returned_date_sk, sr_base.sr_returned_date_sk) AS returned_date_sk,
        cr_base.cr_return_amount,
        cr_base.cr_net_loss,
        cr_base.customer_sk AS cr_customer_sk,
        cr_base.cr_catalog_page_sk,
        cr_base.cr_order_number,
        sr_base.sr_return_amt,
        sr_base.sr_net_loss AS sr_net_loss,
        sr_base.customer_sk AS sr_customer_sk,
        COALESCE(cr_base.d_date, sr_base.d_date) AS return_date,
        COALESCE(cr_base.d_year, sr_base.d_year) AS return_year,
        COALESCE(cr_base.d_month_seq, sr_base.d_month_seq) AS return_month_seq
    FROM cr_base
    FULL OUTER JOIN sr_base
        ON cr_base.cr_returned_date_sk = sr_base.sr_returned_date_sk
),
sales_joined AS (
    SELECT
        fr.returned_date_sk,
        fr.return_date,
        fr.return_year,
        fr.return_month_seq,
        fr.cr_return_amount,
        fr.cr_net_loss,
        fr.sr_return_amt,
        fr.sr_net_loss,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_description,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender
    FROM full_returns fr
    LEFT JOIN catalog_sales cs
        ON fr.cr_order_number = cs.cs_order_number
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_sales_price > 10
      AND ca.ca_state IN ('CA','TX','NY')
      AND cd.cd_gender = 'M'
      AND cp.cp_department = 'Electronics'
)
SELECT
    s.return_date,
    s.cp_catalog_page_id,
    s.cp_department,
    s.c_customer_id,
    s.ca_state,
    s.cd_gender,
    s.cs_quantity,
    s.cs_sales_price,
    s.cs_net_paid,
    s.cr_return_amount,
    s.sr_return_amt,
    s.cr_net_loss,
    s.sr_net_loss,
    s.avg_price_per_page,
    t.promo_tag,
    RANK() OVER (PARTITION BY s.cp_department ORDER BY s.total_page_loss DESC) AS dept_page_rank,
    ROW_NUMBER() OVER (ORDER BY s.total_page_loss DESC) AS overall_rank
FROM (
    SELECT
        sj.*, 
        (
            SELECT AVG(cs2.cs_sales_price)
            FROM catalog_sales cs2
            JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
            WHERE cp2.cp_catalog_page_id = sj.cp_catalog_page_id
        ) AS avg_price_per_page,
        SUM(COALESCE(sj.cr_net_loss,0) + COALESCE(sj.sr_net_loss,0))
            OVER (PARTITION BY sj.cp_catalog_page_id) AS total_page_loss
    FROM sales_joined sj
) s
CROSS JOIN UNNEST(ARRAY['New','Clearance']) AS t(promo_tag)
ORDER BY s.return_date DESC, dept_page_rank
LIMIT 100
