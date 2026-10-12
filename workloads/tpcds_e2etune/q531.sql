WITH aggregated AS (
    SELECT
        ss.s_state,
        COUNT(DISTINCT ss.s_store_sk) AS store_count,
        SUM(ss.s_floor_space) AS total_floor_space,
        AVG(ss.s_floor_space) AS avg_floor_space,
        SUM(ss.s_number_employees) AS total_employees,
        addr.address_count,
        SUM(ct.cp_catalog_page_number) AS total_catalog_page_numbers,
        AVG(ct.t_hour) AS avg_active_hour
    FROM (
        SELECT
            s.s_store_sk,
            s.s_state,
            s.s_floor_space,
            s.s_number_employees,
            s.s_zip,
            s.s_closed_date_sk,
            s.s_rec_start_date,
            s.s_rec_end_date
        FROM store s
        JOIN customer_address ca
            ON s.s_state = ca.ca_state
            AND s.s_zip = ca.ca_zip
    ) ss
    JOIN (
        SELECT
            ca_state,
            COUNT(DISTINCT ca_address_sk) AS address_count
        FROM customer_address
        GROUP BY ca_state
    ) addr
        ON ss.s_state = addr.ca_state
    JOIN (
        SELECT
            cp.cp_catalog_page_sk,
            cp.cp_department,
            cp.cp_catalog_page_number,
            cp.cp_start_date_sk,
            cp.cp_end_date_sk,
            t.t_hour
        FROM catalog_page cp
        JOIN time_dim t
            ON cp.cp_start_date_sk = t.t_time_sk
        WHERE cp.cp_type = 'monthly'
          AND t.t_hour BETWEEN 9 AND 17
    ) ct
        ON ss.s_closed_date_sk BETWEEN ct.cp_start_date_sk AND ct.cp_end_date_sk
    WHERE ss.s_rec_start_date <= DATE '2023-12-31'
      AND ss.s_rec_end_date >= DATE '2023-01-01'
    GROUP BY ss.s_state, addr.address_count
    HAVING COUNT(DISTINCT ss.s_store_sk) >= 5
)
SELECT
    a.s_state,
    a.store_count,
    a.total_floor_space,
    a.avg_floor_space,
    a.total_employees,
    a.address_count,
    a.total_catalog_page_numbers,
    a.avg_active_hour,
    RANK() OVER (ORDER BY a.total_floor_space DESC) AS floor_space_rank
FROM aggregated a
ORDER BY a.total_floor_space DESC
LIMIT 20
