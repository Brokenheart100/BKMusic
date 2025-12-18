using System;
using System.Collections.Generic;
using System.Text;

namespace BKMusic.Shared.Models;
public class PagedResult<T>
{
    public IEnumerable<T> Items { get; }
    public int PageNumber { get; }
    public int PageSize { get; }
    public long TotalCount { get; }
    public bool HasNextPage => PageNumber * PageSize < TotalCount;
    public bool HasPreviousPage => PageNumber > 1;

    public PagedResult(IEnumerable<T> items, int pageNumber, int pageSize, long totalCount)
    {
        Items = items;
        PageNumber = pageNumber;
        PageSize = pageSize;
        TotalCount = totalCount;
    }
}