def lmap(f,xs):
    '''Like map but returns a list instead of a generator'''
    return [f(x) for x in xs]

def apply(fs,t):
    '''Like haskells ap'''
    return tuple(f[1](x) for f,x in zip(fs,t))

def strip_io(tp):
    '''
    IO is somewhat disregarded in the FFI exports. IO CDouble
    looks the same as CDouble from Python's side. So we remove
    the monadic part from our type to process the rest.
    '''
    io = tp.find('IO ')
    if io < 0:
        return '', tp
    else:
        return 'IO ',tp[io+3:]

def tuple_types(hs_type):
    '''
    Nested tuples cannot just be .split(') ('), the
    inner tuples have to be preserved for further processing.
    '''
    subtuples = [hs_type.find('CTuple')]
    while subtuples[-1]+1:
        subtuples.append(hs_type.find('CTuple',subtuples[-1]+1))
    if len(subtuples) == 1:
        return hs_type.split(') (')
    else:
        splits = [hs_type.find(') (',i)+1 if i != len(hs_type) else i
                for i in map(lambda i: match_parens(hs_type,i-1), subtuples) if i
            ]
        res = [hs_type[a:b] for a,b in zip([0]+splits,splits+[len(hs_type)])]
        return res

def match_parens(s, i):
    '''
    Given a string and the index of the opening
    parenthesis returns the index of the closing one.
    '''
    if i < 0:
        return 0
    x = 0
    for it in range(i,len(s)):
        c = s[it]
        if c == '(':
            x += 1
        elif c == ')':
            x -= 1
        if x == 0:
            return it
    else:
        return len(s)

def parse_generator(f_llist, f_carray, f_tuple, f_string, f_default):
    def parser(hs_type):
        ll = hs_type.find('CList ')
        arr = hs_type.find('CArray ')
        tup = hs_type.find('CTuple')
        st = hs_type.find('CWString')
        ## Linked List first
        if ll+1 and (ll < arr or arr < 0) and (ll < tup or tup < 0):
            return f_llist(hs_type[ll+len('CList '):])
        ## Array first
        elif arr+1 and (arr < tup or tup < 0):
            return f_carray(hs_type[arr+len('CArray '):])
        ## Tuple first
        elif tup+1:
            return f_tuple(hs_type[tup+len('CTupleX '):])
        ## String first
        elif st+1:
            return f_string(hs_type[st+len('CWString '):])
        else:
            return f_default(hs_type)
    return parser

