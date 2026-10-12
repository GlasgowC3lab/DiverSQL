WITH returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM store_returns sr
    JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY
        dr.d_year,
        dr.d_month_seq,
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc
)
SELECT
    ra.d_year,
    ra.d_month_seq,
    ra.s_store_id,
    ra.s_store_name,
    ra.r_reason_desc,
    ra.total_net_loss,
    ra.total_return_amount,
    ra.distinct_tickets,
    ra.avg_return_quantity,
    RANK() OVER (PARTITION BY ra.d_year ORDER BY ra.total_net_loss DESC) AS net_loss_rank_year,
    ds.d_date AS store_closed_date,
    wp.wp_url,
    wp.wp_image_count,
    wp.wp_link_count,
    CASE WHEN wp.wp_link_count = 0 THEN NULL ELSE wp.wp_image_count * 1.0 / wp.wp_link_count END AS img_to_link_ratio,
    dwc.d_date AS page_creation_date,
    dwa.d_date AS page_access_date,
    DATE_DIFF('day', dwc.d_date, dwa.d_date) AS days_between_page_creation_and_access
FROM returns_agg ra
JOIN store s2
    ON ra.s_store_sk = s2.s_store_sk
LEFT JOIN date_dim ds
    ON s2.s_closed_date_sk = ds.d_date_sk
JOIN date_dim dwc
    ON dwc.d_year = ra.d_year
   AND dwc.d_month_seq = ra.d_month_seq
   AND dwc.d_dom = 1
JOIN web_page wp
    ON wp.wp_creation_date_sk = dwc.d_date_sk
LEFT JOIN date_dim dwa
    ON wp.wp_access_date_sk = dwa.d_date_sk
ORDER BY ra.total_net_loss DESC
LIMIT 100
