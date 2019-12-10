module symmetry.sildoc;
version(Posix):

version(SILdoc) {} else
{
	struct SILdoc
	{
		string value;
	}
}

