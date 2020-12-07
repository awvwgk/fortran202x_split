module fortran202x_split
  !! An implementation of the Fortran 202X split intrinsic subroutine.
  implicit none

  private
  public :: split, string_tokens

  interface split
    module procedure :: split_tokens, split_first_last, split_pos
  end interface split

contains

  pure subroutine split_tokens(string, set, tokens, separator)
    !! Splits a string into tokens using characters in set as token delimiters.
    !! If present, separator contains the array of token delimiters.
    character(*), intent(in) :: string
    character(*), intent(in) :: set
    character(:), allocatable, intent(out) :: tokens(:)
    character, allocatable, intent(out), optional :: separator(:)

    integer, allocatable :: first(:), last(:)
    integer :: n

    call split(string, set, first, last)
    allocate(character(len=maxval(last - first) + 1) :: tokens(size(first)))

    do concurrent (n = 1:size(tokens))
      tokens(n) = string(first(n):last(n))
    end do

    if (present(separator)) then
      allocate(separator(size(tokens) - 1))
      do concurrent (n = 1:size(tokens) - 1)
        separator(n) = string(first(n+1)-1:first(n+1)-1)
      end do
    end if

  end subroutine split_tokens


  pure subroutine split_first_last(string, set, first, last)
    !! Computes the first and last indices of tokens in input string, delimited
    !! by the characters in set, and stores them into first and last output
    !! arrays.
    character(*), intent(in) :: string
    character(*), intent(in) :: set
    integer, allocatable, intent(out) :: first(:)
    integer, allocatable, intent(out) :: last(:)

    integer, dimension(len(string)+1) :: istart, iend
    integer :: p, n, slen

    slen = len(string)

    n = 0
    if (slen > 0) then
      p = 0
      do while(p < slen)
        n = n+1
        istart(n) = min(p + 1, slen)
        call split(string, set, p)
        iend(n) = p - 1
      end do
    end if

    first = istart(:n)
    last = iend(:n)

  end subroutine split_first_last


  pure subroutine split_pos(string, set, pos, back)
    !! If back is absent, computes the leftmost token delimiter in string whose
    !! position is > pos. If back is present and true, computes the rightmost
    !! token delimiter in string whose position is < pos. The result is stored
    !! in pos.
    character(*), intent(in) :: string
    character(*), intent(in) :: set
    integer, intent(in out) :: pos
    logical, intent(in), optional :: back

    logical :: backward
    integer :: result_pos, bound

    if (len(string) == 0) then
      pos = 1
      return
    end if

    !TODO use optval when implemented in stdlib
    !backward = optval(back, .false.)
    backward = .false.
    if (present(back)) backward = back

    if (backward) then
      bound = min(len(string), max(pos-1, 0))
      result_pos = scan(string(:bound), set, back=.true.)
    else
      result_pos = scan(string(min(pos+1, len(string)):), set) + pos
      if (result_pos < pos+1) result_pos = len(string) + 1
    end if

    pos = result_pos

  end subroutine split_pos


  pure function string_tokens(string, set) result(tokens)
    !! Splits a string into tokens using characters in set as token delimiters.
    character(*), intent(in) :: string
    character(*), intent(in) :: set
    character(:), allocatable :: tokens(:)
    call split_tokens(string, set, tokens)
  end function string_tokens

end module fortran202x_split
