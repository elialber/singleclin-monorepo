using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data.Models;
using SingleClin.API.DTOs.Report;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Builder pattern for constructing complex report queries
    /// </summary>
    public class ReportQueryBuilder<T> where T : class
    {
        private IQueryable<T> _query;
        private readonly List<Expression<Func<T, object>>> _includes = new();
        private readonly List<Expression<Func<T, bool>>> _filters = new();
        private Expression<Func<T, object>>? _orderBy;
        private Expression<Func<T, object>>? _orderByDescending;
        private Expression<Func<T, object>>? _thenBy;
        private Expression<Func<T, object>>? _thenByDescending;
        private int? _take;
        private int? _skip;
        private bool _asNoTracking = true;

        public ReportQueryBuilder(IQueryable<T> baseQuery)
        {
            _query = baseQuery;
        }

        /// <summary>
        /// Add include for eager loading
        /// </summary>
        public ReportQueryBuilder<T> Include(Expression<Func<T, object>> include)
        {
            _includes.Add(include);
            return this;
        }

        /// <summary>
        /// Add where clause
        /// </summary>
        public ReportQueryBuilder<T> Where(Expression<Func<T, bool>> filter)
        {
            _filters.Add(filter);
            return this;
        }

        /// <summary>
        /// Add conditional where clause
        /// </summary>
        public ReportQueryBuilder<T> WhereIf(bool condition, Expression<Func<T, bool>> filter)
        {
            if (condition)
            {
                _filters.Add(filter);
            }
            return this;
        }

        /// <summary>
        /// Add date range filter
        /// </summary>
        public ReportQueryBuilder<T> WithinDateRange<TDate>(
            Expression<Func<T, TDate>> dateSelector,
            DateTime startDate,
            DateTime endDate) where TDate : struct
        {
            var parameter = Expression.Parameter(typeof(T), "x");
            var member = Expression.Invoke(dateSelector, parameter);

            var startConstant = Expression.Constant(startDate, typeof(TDate));
            var endConstant = Expression.Constant(endDate, typeof(TDate));

            var startComparison = Expression.GreaterThanOrEqual(member, startConstant);
            var endComparison = Expression.LessThanOrEqual(member, endConstant);

            var combined = Expression.AndAlso(startComparison, endComparison);
            var lambda = Expression.Lambda<Func<T, bool>>(combined, parameter);

            _filters.Add(lambda);
            return this;
        }

        /// <summary>
        /// Set order by
        /// </summary>
        public ReportQueryBuilder<T> OrderBy(Expression<Func<T, object>> orderBy)
        {
            _orderBy = orderBy;
            _orderByDescending = null;
            return this;
        }

        /// <summary>
        /// Set order by descending
        /// </summary>
        public ReportQueryBuilder<T> OrderByDescending(Expression<Func<T, object>> orderBy)
        {
            _orderByDescending = orderBy;
            _orderBy = null;
            return this;
        }

        /// <summary>
        /// Add then by
        /// </summary>
        public ReportQueryBuilder<T> ThenBy(Expression<Func<T, object>> thenBy)
        {
            _thenBy = thenBy;
            _thenByDescending = null;
            return this;
        }

        /// <summary>
        /// Add then by descending
        /// </summary>
        public ReportQueryBuilder<T> ThenByDescending(Expression<Func<T, object>> thenBy)
        {
            _thenByDescending = thenBy;
            _thenBy = null;
            return this;
        }

        /// <summary>
        /// Set pagination
        /// </summary>
        public ReportQueryBuilder<T> Paginate(int page, int pageSize)
        {
            _skip = (page - 1) * pageSize;
            _take = pageSize;
            return this;
        }

        /// <summary>
        /// Take specific number of records
        /// </summary>
        public ReportQueryBuilder<T> Take(int count)
        {
            _take = count;
            return this;
        }

        /// <summary>
        /// Skip specific number of records
        /// </summary>
        public ReportQueryBuilder<T> Skip(int count)
        {
            _skip = count;
            return this;
        }

        /// <summary>
        /// Enable tracking (disabled by default for reports)
        /// </summary>
        public ReportQueryBuilder<T> WithTracking()
        {
            _asNoTracking = false;
            return this;
        }

        /// <summary>
        /// Build the query
        /// </summary>
        public IQueryable<T> Build()
        {
            // Apply no tracking
            if (_asNoTracking)
            {
                _query = _query.AsNoTracking();
            }

            // Apply includes
            foreach (var include in _includes)
            {
                _query = _query.Include(include);
            }

            // Apply filters
            foreach (var filter in _filters)
            {
                _query = _query.Where(filter);
            }

            // Apply ordering
            if (_orderBy != null)
            {
                var orderedQuery = _query.OrderBy(_orderBy);
                if (_thenBy != null)
                {
                    orderedQuery = orderedQuery.ThenBy(_thenBy);
                }
                else if (_thenByDescending != null)
                {
                    orderedQuery = orderedQuery.ThenByDescending(_thenByDescending);
                }
                _query = orderedQuery;
            }
            else if (_orderByDescending != null)
            {
                var orderedQuery = _query.OrderByDescending(_orderByDescending);
                if (_thenBy != null)
                {
                    orderedQuery = orderedQuery.ThenBy(_thenBy);
                }
                else if (_thenByDescending != null)
                {
                    orderedQuery = orderedQuery.ThenByDescending(_thenByDescending);
                }
                _query = orderedQuery;
            }

            // Apply pagination
            if (_skip.HasValue)
            {
                _query = _query.Skip(_skip.Value);
            }

            if (_take.HasValue)
            {
                _query = _query.Take(_take.Value);
            }

            return _query;
        }

        /// <summary>
        /// Execute query and return list
        /// </summary>
        public async Task<List<T>> ToListAsync(CancellationToken cancellationToken = default)
        {
            return await Build().ToListAsync(cancellationToken);
        }

        /// <summary>
        /// Execute query and return first or default
        /// </summary>
        public async Task<T?> FirstOrDefaultAsync(CancellationToken cancellationToken = default)
        {
            return await Build().FirstOrDefaultAsync(cancellationToken);
        }

        /// <summary>
        /// Execute query and return count
        /// </summary>
        public async Task<int> CountAsync(CancellationToken cancellationToken = default)
        {
            // Don't apply skip/take for count
            var countQuery = _query;

            if (_asNoTracking)
            {
                countQuery = countQuery.AsNoTracking();
            }

            foreach (var filter in _filters)
            {
                countQuery = countQuery.Where(filter);
            }

            return await countQuery.CountAsync(cancellationToken);
        }

        /// <summary>
        /// Check if any records exist
        /// </summary>
        public async Task<bool> AnyAsync(CancellationToken cancellationToken = default)
        {
            // Don't apply skip/take for any check
            var anyQuery = _query;

            if (_asNoTracking)
            {
                anyQuery = anyQuery.AsNoTracking();
            }

            foreach (var filter in _filters)
            {
                anyQuery = anyQuery.Where(filter);
            }

            return await anyQuery.AnyAsync(cancellationToken);
        }

        /// <summary>
        /// Project to different type
        /// </summary>
        public ReportQueryBuilder<TResult> Select<TResult>(Expression<Func<T, TResult>> selector) where TResult : class
        {
            var projectedQuery = Build().Select(selector);
            return new ReportQueryBuilder<TResult>(projectedQuery);
        }
    }

    /// <summary>
    /// Extension methods for creating report query builders
    /// </summary>
    public static class ReportQueryBuilderExtensions
    {
        /// <summary>
        /// Create a report query builder for the queryable
        /// </summary>
        public static ReportQueryBuilder<T> BuildReport<T>(this IQueryable<T> query) where T : class
        {
            return new ReportQueryBuilder<T>(query);
        }

        /// <summary>
        /// Filter transactions by date range
        /// </summary>
        public static ReportQueryBuilder<Transaction> WithinPeriod(
            this ReportQueryBuilder<Transaction> builder,
            DateTime startDate,
            DateTime endDate)
        {
            return builder.Where(t => t.CreatedAt >= startDate && t.CreatedAt <= endDate);
        }

        /// <summary>
        /// Filter by clinic IDs
        /// </summary>
        public static ReportQueryBuilder<Transaction> ForClinics(
            this ReportQueryBuilder<Transaction> builder,
            List<Guid>? clinicIds)
        {
            return builder.WhereIf(
                clinicIds?.Any() == true,
                t => clinicIds!.Contains(t.ClinicId));
        }

        /// <summary>
        /// Filter by service types
        /// </summary>
        public static ReportQueryBuilder<Transaction> ForServiceTypes(
            this ReportQueryBuilder<Transaction> builder,
            List<string>? serviceTypes)
        {
        return builder.WhereIf(
            serviceTypes?.Any() == true,
            t => t.ServiceType != null && serviceTypes!.Contains(t.ServiceType));
        }

        /// <summary>
        /// Include related entities for transactions
        /// </summary>
        public static ReportQueryBuilder<Transaction> IncludeRelated(
            this ReportQueryBuilder<Transaction> builder)
        {
            return builder
                .Include(t => t.Clinic)
                .Include(t => t.UserPlan)
                .Include(t => t.UserPlan.Plan)
                .Include(t => t.UserPlan.User);
        }
    }
}
