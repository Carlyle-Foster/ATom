package ATom

HandledArray :: struct(T: typeid) {
    _inner: [dynamic]HandledData(T),
    vacancies: [dynamic]i16,
}
HandledData :: struct(T: typeid) {
    generation: i16,
    _inner: T,
}
Handle :: struct(T: typeid) {
    generation, index: i16,
}
invalidHandle :: proc($T: typeid) -> Handle(T) { return {-1, -1} }
handleValid :: proc(h: Handle($T)) -> bool { return h.index >= 0 }

makeHandledArray :: proc($T: typeid, capacity: i16 = 16) -> HandledArray(T) {
    return {
        _inner = make([dynamic]HandledData(T), 0, capacity),
        vacancies = make([dynamic]i16, 0, capacity),
    }
}
handleRetrieve :: proc(ha: ^HandledArray($T), h: Handle(T)) -> Maybe(^T) {
    a := &ha._inner

    if (h.index >= i16(len(a))) || (h.index < 0) { return nil }

    result := &a[h.index]
    if h.generation != result.generation { return nil }
    else { return &result._inner }
}
handleFromIndex :: proc(ha: ^HandledArray($T), index: i16) -> Handle(T) {
    return Handle(T) {
        generation = ha._inner[index].generation, 
        index = index, 
    }
}
handlePush :: proc(ha: ^HandledArray($T), item: T) -> Handle(T) {
    a := &ha._inner
    v := &ha.vacancies

    i: i16
    if len(v) > 0 {
        i = pop(v)
        a[i].generation *= -1
        a[i]._inner = item
        return {a[i].generation, i}
    } else {
        i = i16(len(a))
        append(a, HandledData(T){0, item})
        return {0, i}
    }
}
handleRemove :: proc(ha: ^HandledArray($T), h: Handle(T)) -> Maybe(T) {
    a := &ha._inner
    v := &ha.vacancies

    item := &a[h.index]
    if item.generation == h.generation {
        item.generation += 1
        item.generation *= -1
        append(v, h.index)
        return item._inner
    } else {
        return nil
    }
    
}