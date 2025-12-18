using System;
using System.Collections.Generic;
using System.Text;

namespace BKMusic.Shared.Domain;
public abstract class Entity<TId> : IEquatable<Entity<TId>>
{
    public TId Id { get; protected set; }

    protected Entity(TId id)
    {
        Id = id;
    }

    // 这一步很重要：实体相等性是基于 ID 的，而不是基于对象引用
    public bool Equals(Entity<TId>? other)
    {
        if (other is null) return false;
        if (ReferenceEquals(this, other)) return true;
        return EqualityComparer<TId>.Default.Equals(Id, other.Id);
    }

    public override bool Equals(object? obj)
    {
        if (obj is null) return false;
        if (obj.GetType() != GetType()) return false;
        if (obj is not Entity<TId> entity) return false;
        return Equals(entity);
    }

    public override int GetHashCode()
    {
        return Id!.GetHashCode() * 41;
    }
}