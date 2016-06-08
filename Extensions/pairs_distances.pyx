"""
This is a C compiled module to compute atomic pair distances.
"""
#from libc.math cimport sqrt, abs
import cython
cimport cython
import numpy as np
cimport numpy as np
from numpy cimport ndarray
from cython.parallel import prange

# declare types
NUMPY_FLOAT32 = np.float32
NUMPY_INT32   = np.int32
ctypedef np.float32_t C_FLOAT32
ctypedef np.int32_t   C_INT32

# declare constants
cdef C_FLOAT32 BOX_LENGTH      = 1.0
cdef C_FLOAT32 HALF_BOX_LENGTH = 0.5
cdef C_FLOAT32 FLOAT32_ZERO    = 0.0
cdef C_INT32   INT32_ZERO      = 0
cdef C_INT32   INT32_ONE       = 1


cdef extern from "math.h":
    C_FLOAT32 floor(C_FLOAT32 x) nogil
    C_FLOAT32 ceil(C_FLOAT32 x)  nogil
    C_FLOAT32 sqrt(C_FLOAT32 x)  nogil

    
cdef inline C_FLOAT32 round(C_FLOAT32 num) nogil:
    return floor(num + HALF_BOX_LENGTH) if (num > FLOAT32_ZERO) else ceil(num - HALF_BOX_LENGTH)


      
############################################################################################        
################################# C DIFFERENCE DEFINITIONS #################################

######## From To differences ########
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
cdef void _from_to_boxpoints_realdifferences_PBC( C_FLOAT32[:,:] boxPointsFrom,
                                                  C_FLOAT32[:,:] boxPointsTo,
                                                  C_FLOAT32[:,:] basis,
                                                  C_FLOAT32[:,:] differences,
                                                  C_INT32        ncores = 1) nogil:
    # declare variables
    cdef C_INT32 i
    cdef C_FLOAT32 box_dx, box_dy, box_dz
    # loop
    #for i in prange(size, nogil=True, num_threads=ncores): # Error compiling Cython file: Cannot read reduction variable in loop body
    for i from INT32_ZERO <= i < <C_INT32>boxPointsFrom.shape[0]:
        # calculate difference
        box_dx = boxPointsTo[i,0]-boxPointsFrom[i,0]
        box_dy = boxPointsTo[i,1]-boxPointsFrom[i,1]
        box_dz = boxPointsTo[i,2]-boxPointsFrom[i,2]
        box_dx -= round(box_dx)
        box_dy -= round(box_dy)
        box_dz -= round(box_dz)
        # get real difference
        differences[i,0] = box_dx*basis[0,0] + box_dy*basis[1,0] + box_dz*basis[2,0]
        differences[i,1] = box_dx*basis[0,1] + box_dy*basis[1,1] + box_dz*basis[2,1]
        differences[i,2] = box_dx*basis[0,2] + box_dy*basis[1,2] + box_dz*basis[2,2]

@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
cdef void _from_to_realpoints_realdifferences_IBC( C_FLOAT32[:,:] realPointsFrom,
                                                   C_FLOAT32[:,:] realPointsTo,
                                                   C_FLOAT32[:,:] differences,
                                                   C_INT32        ncores = 1) nogil:
    # declare variables
    cdef C_INT32 i
    # loop
    for i in prange(INT32_ZERO, <C_INT32>realPointsFrom.shape[0], INT32_ONE, nogil=True, num_threads=ncores):
    #for i from INT32_ZERO <= i < <C_INT32>boxPointsFrom.shape[0]:
        # calculate difference
        differences[i,0] = realPointsTo[i,0]-realPointsFrom[i,0]
        differences[i,1] = realPointsTo[i,1]-realPointsFrom[i,1]
        differences[i,2] = realPointsTo[i,2]-realPointsFrom[i,2]
        
        
        
######## point differences ########       
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
cdef void _boxcoords_realdifferences_to_boxpoint_PBC( C_FLOAT32[:]   boxPoint,
                                                      C_FLOAT32[:,:] boxCoords,
                                                      C_FLOAT32[:,:] basis,
                                                      C_FLOAT32[:,:] differences,
                                                      C_INT32        ncores = 1) nogil:
    # declare variables
    cdef C_INT32 i, size
    cdef C_FLOAT32 box_dx, box_dy, box_dz
    cdef C_FLOAT32 atomBox_x, atomBox_y, atomBox_z
    # compute size
    size = <C_INT32>boxCoords.shape[0]
    # get point coordinates
    atomBox_x = boxPoint[0]
    atomBox_y = boxPoint[1]
    atomBox_z = boxPoint[2]    
    # loop
    #for i in prange(size, nogil=True, num_threads=ncores): # Error compiling Cython file: Cannot read reduction variable in loop body
    for i in range(size):
        # calculate difference
        box_dx = atomBox_x - boxCoords[i,0]
        box_dy = atomBox_y - boxCoords[i,1]
        box_dz = atomBox_z - boxCoords[i,2]
        box_dx -= round(box_dx)
        box_dy -= round(box_dy)
        box_dz -= round(box_dz)
        # get real difference
        differences[i,0] = box_dx*basis[0,0] + box_dy*basis[1,0] + box_dz*basis[2,0]
        differences[i,1] = box_dx*basis[0,1] + box_dy*basis[1,1] + box_dz*basis[2,1]
        differences[i,2] = box_dx*basis[0,2] + box_dy*basis[1,2] + box_dz*basis[2,2]

@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
cdef void _realcoords_realdifferences_to_realpoint_IBC( C_FLOAT32[:]   realPoint,
                                                        C_FLOAT32[:,:] realCoords,
                                                        C_FLOAT32[:,:] differences,
                                                        C_INT32        ncores=1) nogil:
    # declare variables
    cdef C_INT32 i, size
    cdef C_FLOAT32 atomReal_x, atomReal_y, atomReal_z
    # compute size
    size = <C_INT32>realCoords.shape[0]
    # get point coordinates
    atomReal_x = realPoint[0]
    atomReal_y = realPoint[1]
    atomReal_z = realPoint[2]    
    # loop
    for i in prange(size, nogil=True, num_threads=ncores): 
    #for i in range(size):
        # calculate difference
        differences[i,0] = atomReal_x-realCoords[i,0]
        differences[i,1] = atomReal_y-realCoords[i,1]
        differences[i,2] = atomReal_z-realCoords[i,2]
        
        
            
######## index differences ########
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)               
cdef void _boxcoords_realdifferences_to_indexcoords_PBC( C_INT32        atomIndex,
                                                         C_FLOAT32[:,:] boxCoords,
                                                         C_FLOAT32[:,:] basis,
                                                         C_FLOAT32[:,:] differences,
                                                         bint           allAtoms = True,
                                                         C_INT32        ncores = 1) nogil:                          
    # declare variables
    cdef C_INT32 i, startIndex, endIndex
    cdef C_FLOAT32 box_dx, box_dy, box_dz
    cdef C_FLOAT32 atomBox_x, atomBox_y, atomBox_z
    # get point coordinates
    atomBox_x = boxCoords[atomIndex,0]
    atomBox_y = boxCoords[atomIndex,1]
    atomBox_z = boxCoords[atomIndex,2] 
    # start index
    if allAtoms:
        startIndex = INT32_ZERO
    else:
        startIndex = <C_INT32>atomIndex
    endIndex = <C_INT32>boxCoords.shape[0]
    # loop
    #for i in prange(startIndex, endIndex, INT32_ONE, nogil=True, num_threads=ncores): # Error compiling Cython file: Cannot read reduction variable in loop body
    for i from startIndex <= i < endIndex:
        # calculate difference
        box_dx = atomBox_x - boxCoords[i,0]
        box_dy = atomBox_y - boxCoords[i,1]
        box_dz = atomBox_z - boxCoords[i,2]
        box_dx -= round(box_dx)
        box_dy -= round(box_dy)
        box_dz -= round(box_dz)
        # get real difference
        differences[i,0] = box_dx*basis[0,0] + box_dy*basis[1,0] + box_dz*basis[2,0]
        differences[i,1] = box_dx*basis[0,1] + box_dy*basis[1,1] + box_dz*basis[2,1]
        differences[i,2] = box_dx*basis[0,2] + box_dy*basis[1,2] + box_dz*basis[2,2]                                                  
                                                    
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
cdef void _realcoords_realdifferences_to_indexcoords_IBC( C_INT32        atomIndex,
                                                          C_FLOAT32[:,:] realCoords,
                                                          C_FLOAT32[:,:] differences,
                                                          bint           allAtoms = True,
                                                          C_INT32        ncores=1) nogil:   
    # declare variables
    cdef C_INT32 i, startIndex, endIndex
    cdef C_FLOAT32 atomReal_x, atomReal_y, atomReal_z
    # get point coordinates
    atomReal_x = realCoords[atomIndex,0]
    atomReal_y = realCoords[atomIndex,1]
    atomReal_z = realCoords[atomIndex,2] 
    # start index
    if allAtoms:
        startIndex = INT32_ZERO
    else:
        startIndex = <C_INT32>atomIndex
    endIndex = <C_INT32>realCoords.shape[0]
    # loop
    for i in prange(startIndex, endIndex, INT32_ONE, nogil=True, num_threads=ncores): 
    #for i from startIndex <= i < endIndex:
        # calculate difference
        differences[i,0] = atomReal_x - realCoords[i,0]
        differences[i,1] = atomReal_y - realCoords[i,1]
        differences[i,2] = atomReal_z - realCoords[i,2]

   

   
############################################################################################        
################################## C DISTANCE DEFINITIONS ##################################        
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
cdef void _boxcoords_realdistances_to_boxpoint_PBC( C_FLOAT32[:]   boxPoint,
                                                    C_FLOAT32[:,:] boxCoords,
                                                    C_FLOAT32[:,:] basis,
                                                    C_FLOAT32[:]   distances,
                                                    C_INT32        ncores = 1) nogil:
    # declare variables
    cdef C_INT32 i, size
    cdef C_FLOAT32 box_dx, box_dy, box_dz
    cdef C_FLOAT32 real_dx, real_dy, real_dz,
    cdef C_FLOAT32 atomBox_x, atomBox_y, atomBox_z
    # compute size
    size = <C_INT32>boxCoords.shape[0]
    # get point coordinates
    atomBox_x = boxPoint[0]
    atomBox_y = boxPoint[1]
    atomBox_z = boxPoint[2]    
    # loop
    #for i in prange(size, nogil=True, num_threads=ncores): # Error compiling Cython file: Cannot read reduction variable in loop body
    for i in range(size):
        # calculate difference
        box_dx = boxCoords[i,0]-atomBox_x
        box_dy = boxCoords[i,1]-atomBox_y
        box_dz = boxCoords[i,2]-atomBox_z
        box_dx -= round(box_dx)
        box_dy -= round(box_dy)
        box_dz -= round(box_dz)
        # get real difference
        real_dx = box_dx*basis[0,0] + box_dy*basis[1,0] + box_dz*basis[2,0]
        real_dy = box_dx*basis[0,1] + box_dy*basis[1,1] + box_dz*basis[2,1]
        real_dz = box_dx*basis[0,2] + box_dy*basis[1,2] + box_dz*basis[2,2]
        # calculate distance         
        distances[i] = <C_FLOAT32>sqrt(real_dx*real_dx + real_dy*real_dy + real_dz*real_dz)


@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)               
cdef void _boxcoords_realdistances_to_indexcoords_PBC( C_INT32        atomIndex,
                                                       C_FLOAT32[:,:] boxCoords,
                                                       C_FLOAT32[:,:] basis,
                                                       C_FLOAT32[:]   distances,
                                                       bint           allAtoms = True,
                                                       C_INT32        ncores = 1) nogil:                          
    # declare variables
    cdef C_INT32 i, startIndex, endIndex
    cdef C_FLOAT32 box_dx, box_dy, box_dz
    cdef C_FLOAT32 real_dx, real_dy, real_dz,
    cdef C_FLOAT32 atomBox_x, atomBox_y, atomBox_z
    # get point coordinates
    atomBox_x = boxCoords[atomIndex,0]
    atomBox_y = boxCoords[atomIndex,1]
    atomBox_z = boxCoords[atomIndex,2] 
    # start index
    if allAtoms:
        startIndex = INT32_ZERO
    else:
        startIndex = <C_INT32>atomIndex
    endIndex = <C_INT32>boxCoords.shape[0]
    # loop
    #for i in prange(startIndex, endIndex, INT32_ONE, nogil=True, num_threads=ncores): # Error compiling Cython file: Cannot read reduction variable in loop body
    for i from startIndex <= i < endIndex:
        # calculate difference
        box_dx = boxCoords[i,0]-atomBox_x
        box_dy = boxCoords[i,1]-atomBox_y
        box_dz = boxCoords[i,2]-atomBox_z
        box_dx -= round(box_dx)
        box_dy -= round(box_dy)
        box_dz -= round(box_dz)
        # get real difference
        real_dx = box_dx*basis[0,0] + box_dy*basis[1,0] + box_dz*basis[2,0]
        real_dy = box_dx*basis[0,1] + box_dy*basis[1,1] + box_dz*basis[2,1]
        real_dz = box_dx*basis[0,2] + box_dy*basis[1,2] + box_dz*basis[2,2]
        # calculate distance         
        distances[i] = <C_FLOAT32>sqrt(real_dx*real_dx + real_dy*real_dy + real_dz*real_dz)                                                    
                                                    
                                     
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
cdef void _realcoords_realdistances_to_realpoint_IBC( C_FLOAT32[:]   realPoint,
                                                      C_FLOAT32[:,:] realCoords,
                                                      C_FLOAT32[:]   distances,
                                                      C_INT32        ncores=1) nogil:
    # declare variables
    cdef C_INT32 i, size
    cdef C_FLOAT32 real_dx, real_dy, real_dz
    cdef C_FLOAT32 atomReal_x, atomReal_y, atomReal_z
    # compute size
    size = <C_INT32>realCoords.shape[0]
    # get point coordinates
    atomReal_x = realPoint[0]
    atomReal_y = realPoint[1]
    atomReal_z = realPoint[2]    
    # loop
    for i in prange(size, nogil=True, num_threads=ncores): 
    #for i in range(size):
        # calculate difference
        real_dx = realCoords[i,0]-atomReal_x
        real_dy = realCoords[i,1]-atomReal_y
        real_dz = realCoords[i,2]-atomReal_z
        # calculate distance         
        distances[i] = <C_FLOAT32>sqrt(real_dx*real_dx + real_dy*real_dy + real_dz*real_dz)

        
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
cdef void _realcoords_realdistances_to_indexcoords_IBC( C_INT32        atomIndex,
                                                        C_FLOAT32[:,:] realCoords,
                                                        C_FLOAT32[:]   distances,
                                                        bint           allAtoms = True,
                                                        C_INT32        ncores=1) nogil:   
    # declare variables
    cdef C_INT32 i, startIndex, endIndex
    cdef C_FLOAT32 real_dx, real_dy, real_dz
    cdef C_FLOAT32 atomReal_x, atomReal_y, atomReal_z
    # get point coordinates
    atomReal_x = realCoords[atomIndex,0]
    atomReal_y = realCoords[atomIndex,1]
    atomReal_z = realCoords[atomIndex,2] 
    # start index
    if allAtoms:
        startIndex = INT32_ZERO
    else:
        startIndex = <C_INT32>atomIndex
    endIndex = <C_INT32>realCoords.shape[0]
    # loop
    for i in prange(startIndex, endIndex, INT32_ONE, nogil=True, num_threads=ncores): 
    #for i from startIndex <= i < endIndex:
        # calculate difference
        real_dx = realCoords[i,0]-atomReal_x
        real_dy = realCoords[i,1]-atomReal_y
        real_dz = realCoords[i,2]-atomReal_z
        # calculate distance         
        distances[i] = <C_FLOAT32>sqrt(real_dx*real_dx + real_dy*real_dy + real_dz*real_dz)
        
        
        
        
############################################################################################        
############################## PYTHON DIFFERENCE DEFINITIONS ###############################
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def from_to_points_differences( ndarray[C_FLOAT32, ndim=2] pointsFrom  not None,
                                ndarray[C_FLOAT32, ndim=2] pointsTo not None,
                                C_FLOAT32[:,:]             basis not None,
                                bint                       isPBC, 
                                C_INT32                    ncores = 1):                       
    """
    Compute point to point vector difference between two atomic coordinates arrays taking 
    into account periodic or infinite boundary conditions. Difference is calculated as 
    the following:
    
    .. math::
            differences[i,:] = boundaryConditions( pointsTo[i,:] - pointsFrom[i,:] )
    
    :Arguments:
       #. pointsFrom (float32 (n,3) numpy.ndarray): The first atomic coordinates array of 
          the same shape as pointsTo.
       #. pointsTo (float32 (n,3) numpy.ndarray): The second atomic coordinates array of 
          the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. differences (float32 (n,3) numpy.ndarray): The computed differences array.   
    """
    cdef ndarray[C_FLOAT32,  mode="c", ndim=2] differences = np.empty((<C_INT32>pointsFrom.shape[0],3), dtype=NUMPY_FLOAT32)
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        _from_to_boxpoints_realdifferences_PBC( boxPointsFrom = pointsFrom,
                                                boxPointsTo   = pointsTo,
                                                basis         = basis,
                                                differences   = differences,
                                                ncores        = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        _from_to_realpoints_realdifferences_IBC( realPointsFrom = pointsFrom,
                                                 realPointsTo   = pointsTo,
                                                 differences    = differences,
                                                 ncores         = ncores)
    # return differences
    return differences

    
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def pairs_differences_to_point( ndarray[C_FLOAT32, ndim=1] point  not None,
                                ndarray[C_FLOAT32, ndim=2] coords not None,
                                C_FLOAT32[:,:]             basis not None,
                                bint                       isPBC, 
                                C_INT32                    ncores = 1):                        
    """
    Compute differences between one atomic coordinates arrays to a point coordinates  
    taking into account periodic or infinite boundary conditions. Difference is 
    calculated as the following:
    
    .. math::
            differences[i,:] = boundaryConditions( point[0,:] - coords[i,:] )
    
    :Arguments:
       #. point (float32 (1,3) numpy.ndarray): The atomic coordinates point.
       #. coords (float32 (n,3) numpy.ndarray): The atomic coordinates array of the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. differences (float32 (n,3) numpy.ndarray): The computed differences array.   
    """
    cdef ndarray[C_FLOAT32,  mode="c", ndim=2] differences = np.empty((<C_INT32>coords.shape[0],3), dtype=NUMPY_FLOAT32)
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        _boxcoords_realdifferences_to_boxpoint_PBC( boxPoint    = point,
                                                    boxCoords   = coords,
                                                    basis       = basis,
                                                    differences = differences,
                                                    ncores      = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        _realcoords_realdifferences_to_realpoint_IBC( realPoint   = point,
                                                      realCoords  = coords,
                                                      differences = differences,
                                                      ncores      = ncores)
    # return differences
    return differences


@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def pairs_differences_to_indexcoords( C_INT32                    atomIndex,
                                      ndarray[C_FLOAT32, ndim=2] coords not None,
                                      C_FLOAT32[:,:]             basis not None,
                                      bint                       isPBC,
                                      bint                       allAtoms = True,
                                      C_INT32                    ncores = 1):                       
    """
    Compute differences between one atomic coordinates arrays to a point coordinates   
    given its index in the coordinates array and taking into account periodic or 
    infinite boundary conditions. Difference is calculated as the following:
    
    .. math::
            differences[i,:] = boundaryConditions( coords[atomIndex,:] - coords[i,:] )
    
    :Arguments:
       #. atomIndex (int32): The index of the atomic coordinates point.
       #. coords (float32 (n,3) numpy.ndarray): The atomic coordinates array of the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. differences (float32 (n,3) numpy.ndarray): The computed differences array.   
    """
    cdef ndarray[C_FLOAT32,  mode="c", ndim=2] differences = np.empty((<C_INT32>coords.shape[0],3), dtype=NUMPY_FLOAT32)
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        _boxcoords_realdifferences_to_indexcoords_PBC( atomIndex   = atomIndex,
                                                       boxCoords   = coords,
                                                       basis       = basis,
                                                       differences = differences,
                                                       allAtoms    = allAtoms,
                                                       ncores      = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        _realcoords_realdifferences_to_indexcoords_IBC( atomIndex   = atomIndex,
                                                        realCoords  = coords,
                                                        differences = differences,
                                                        allAtoms    = allAtoms,
                                                        ncores      = ncores)
    # return differences
    return differences    

    
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def pairs_differences_to_multi_points( ndarray[C_FLOAT32, ndim=2] points not None,
                                       ndarray[C_FLOAT32, ndim=2] coords not None,
                                       C_FLOAT32[:,:]             basis not None,
                                       bint                       isPBC, 
                                       C_INT32                    ncores = 1):                       
    """
    Compute differences between one atomic coordinates arrays to a multiple points   
    coordinates taking into account periodic or infinite boundary conditions. 
    Difference is calculated as the following:
    
    .. math::
            differences[i,:,k] = boundaryConditions( points[k,:] - coords[i,:] )
    
    :Arguments:
       #. points (float32 (k,3) numpy.ndarray): The multiple atomic coordinates points.
       #. coords (float32 (n,3) numpy.ndarray): The atomic coordinates array of the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. differences (float32 (n,3,k) numpy.ndarray): The computed differences array.   
    """
    cdef C_INT32 i
    cdef ndarray[C_FLOAT32,  mode="c", ndim=3] differences = np.empty( (<C_INT32>coords.shape[0], 
                                                                        3,
                                                                        <C_INT32>points.shape[1]), 
                                                                        dtype=NUMPY_FLOAT32)
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        for i from INT32_ZERO <= i < <C_INT32>points.shape[1]:
            _boxcoords_realdifferences_to_boxpoint_PBC( boxPoint  = points[:,i],
                                                      boxCoords   = coords,
                                                      basis       = basis,
                                                      differences = differences[:,:,i],
                                                      ncores      = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        for i from INT32_ZERO <= i < <C_INT32>points.shape[1]:
            _realcoords_realdifferences_to_realpoint_IBC( realPoint   = points[:,i],
                                                          realCoords  = coords,
                                                          differences = differences[:,:,i],
                                                          ncores      = ncores)
    # return differences
    return differences    
    
    
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def pairs_differences_to_multi_indexcoords( ndarray[C_INT32, ndim=1]   indexes,
                                            ndarray[C_FLOAT32, ndim=2] coords not None,
                                            C_FLOAT32[:,:]             basis not None,
                                            bint                       isPBC,
                                            bint                       allAtoms = True,
                                            C_INT32                    ncores = 1):                       
    """
    Compute differences between one atomic coordinates arrays to a points coordinates   
    given their indexes in the coordinates array and taking into account periodic or 
    infinite boundary conditions. Difference is calculated as the following:
    
    .. math::
            differences[i,:,k] = boundaryConditions( coords[indexes[k],:] - coords[i,:] )
    
    :Arguments:
       #. indexes (int32 (k,3) numpy.ndarray): The atomic coordinates indexes array.
       #. coords (float32 (n,3) numpy.ndarray): The atomic coordinates array of the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. differences (float32 (n,3,k) numpy.ndarray): The computed differences array.   
    """
    cdef C_INT32 i
    cdef ndarray[C_FLOAT32,  mode="c", ndim=3] differences = np.empty( (<C_INT32>coords.shape[0], 
                                                                        3,
                                                                        <C_INT32>indexes.shape[0]), 
                                                                        dtype=NUMPY_FLOAT32)                                                                      
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        for i from INT32_ZERO <= i < <C_INT32>indexes.shape[0]:
            _boxcoords_realdifferences_to_indexcoords_PBC( atomIndex   = indexes[i],
                                                           boxCoords   = coords,
                                                           basis       = basis,
                                                           differences = differences[:,:,i],
                                                           allAtoms    = allAtoms,
                                                           ncores      = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        for i from INT32_ZERO <= i < <C_INT32>indexes.shape[0]:
            _realcoords_realdifferences_to_indexcoords_IBC( atomIndex   = indexes[i],
                                                            realCoords  = coords,
                                                            differences = differences[:,:,i],
                                                            allAtoms    = allAtoms,
                                                            ncores      = ncores)
    # return differences
    return differences 
    
    

    
############################################################################################        
############################### PYTHON DISTANCE DEFINITIONS ################################
@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def pairs_distances_to_point( ndarray[C_FLOAT32, ndim=1] point  not None,
                              ndarray[C_FLOAT32, ndim=2] coords not None,
                              C_FLOAT32[:,:]             basis not None,
                              bint                       isPBC, 
                              C_INT32                    ncores = 1):                       
    
    """
    Compute distances between one atomic coordinates arrays to a point coordinates  
    taking into account periodic or infinite boundary conditions. Distances is 
    calculated as the following:
    
    .. math::
            distances[i] = \sqrt{ \sum_{d}^{3}{ boundaryConditions( point[0,d] - coords[i,d] )^{2}} }
    
    :Arguments:
       #. point (float32 (1,3) numpy.ndarray): The atomic coordinates point.
       #. coords (float32 (n,3) numpy.ndarray): The atomic coordinates array of the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. distances (float32 (n,) numpy.ndarray): The computed distances array.   
    """
    cdef ndarray[C_FLOAT32,  mode="c", ndim=1] distances = np.empty((<C_INT32>coords.shape[0],), dtype=NUMPY_FLOAT32)
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        _boxcoords_realdistances_to_boxpoint_PBC( boxPoint  = point,
                                                  boxCoords = coords,
                                                  basis     = basis,
                                                  distances = distances,
                                                  ncores    = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        _realcoords_realdistances_to_realpoint_IBC( realPoint  = point,
                                                    realCoords = coords,
                                                    distances  = distances,
                                                    ncores     = ncores)
    # return distances
    return distances


@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def pairs_distances_to_indexcoords( C_INT32                    atomIndex,
                                    ndarray[C_FLOAT32, ndim=2] coords not None,
                                    C_FLOAT32[:,:]             basis not None,
                                    bint                       isPBC,
                                    bint                       allAtoms = True,
                                    C_INT32                    ncores = 1):                       
    
    """
    Compute distances between one atomic coordinates arrays to a points coordinates   
    given their indexes in the coordinates array and taking into account periodic or 
    infinite boundary conditions. Distances is calculated as the following:
    
    .. math::
            distances[i] = \sqrt{ \sum_{d}^{3}{ boundaryConditions( coords[atomIndex[i],d] - coords[i,d] )^{2}} }
    
    :Arguments:
       #. point (float32 (1,3) numpy.ndarray): The atomic coordinates point.
       #. coords (float32 (n,3) numpy.ndarray): The atomic coordinates array of the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. distances (float32 (n,) numpy.ndarray): The computed distances array.   
    """
    cdef ndarray[C_FLOAT32,  mode="c", ndim=1] distances = np.empty((<C_INT32>coords.shape[0],), dtype=NUMPY_FLOAT32)
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        _boxcoords_realdistances_to_indexcoords_PBC( atomIndex = atomIndex,
                                                     boxCoords = coords,
                                                     basis     = basis,
                                                     distances = distances,
                                                     allAtoms  = allAtoms,
                                                     ncores    = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        _realcoords_realdistances_to_indexcoords_IBC( atomIndex  = atomIndex,
                                                      realCoords = coords,
                                                      distances  = distances,
                                                      allAtoms   = allAtoms,
                                                      ncores     = ncores)
    # return distances
    return distances    


@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def pairs_distances_to_multi_points( ndarray[C_FLOAT32, ndim=2] points not None,
                                     ndarray[C_FLOAT32, ndim=2] coords not None,
                                     C_FLOAT32[:,:]             basis not None,
                                     bint                       isPBC, 
                                     C_INT32                    ncores = 1):                       
    """
    Compute distances between one atomic coordinates arrays to a multiple points   
    coordinates taking into account periodic or infinite boundary conditions. 
    Distances is calculated as the following:
    
    .. math::
            distances[i,k] = \sqrt{ \sum_{d}^{3}{ boundaryConditions( points[k,d] - coords[i,d] )^{2}} }
            
    :Arguments:
       #. points (float32 (k,3) numpy.ndarray): The multiple atomic coordinates points.
       #. coords (float32 (n,3) numpy.ndarray): The atomic coordinates array of the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. distances (float32 (n,) numpy.ndarray): The computed distances array.   
    """
    cdef C_INT32 i
    cdef ndarray[C_FLOAT32,  mode="c", ndim=2] distances = np.empty( (<C_INT32>coords.shape[0], 
                                                                      <C_INT32>points.shape[1]), 
                                                                      dtype=NUMPY_FLOAT32)
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        for i from INT32_ZERO <= i < <C_INT32>points.shape[1]:
            _boxcoords_realdistances_to_boxpoint_PBC( boxPoint  = points[:,i],
                                                      boxCoords = coords,
                                                      basis     = basis,
                                                      distances = distances[:,i],
                                                      ncores    = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        for i from INT32_ZERO <= i < <C_INT32>points.shape[1]:
            _realcoords_realdistances_to_realpoint_IBC( realPoint  = points[:,i],
                                                        realCoords = coords,
                                                        distances  = distances[:,i],
                                                        ncores     = ncores)
    # return distances
    return distances    
    

@cython.nonecheck(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.always_allow_keywords(False)
def pairs_distances_to_multi_indexcoords( ndarray[C_INT32, ndim=1]   indexes,
                                          ndarray[C_FLOAT32, ndim=2] coords not None,
                                          C_FLOAT32[:,:]             basis not None,
                                          bint                       isPBC,
                                          bint                       allAtoms = True,
                                          C_INT32                    ncores = 1):                       
    """
    Compute distances between one atomic coordinates arrays to a points coordinates   
    given their indexes in the coordinates array and taking into account periodic or 
    infinite boundary conditions. Distances is calculated as the following:
    
    .. math::
            distances[i,k] = \sqrt{ \sum_{d}^{3}{ boundaryConditions( coords[indexes[k],:]  - coords[i,d] )^{2}} }
            
    :Arguments:
       #. indexes (int32 (k,3) numpy.ndarray): The atomic coordinates indexes array.
       #. coords (float32 (n,3) numpy.ndarray): The atomic coordinates array of the same shape as pointsFrom.
       #. basis (float32 (3,3) numpy.ndarray): The (3x3) boundary conditions box vectors.
       #. isPBC (bool): Whether it is a periodic boundary conditions or infinite.
       #. ncores (int32) [default=1]: The number of cores to use. 
       
    :Returns:
       #. distances (float32 (n,) numpy.ndarray): The computed distances array.   
    """
    cdef C_INT32 i
    cdef ndarray[C_FLOAT32,  mode="c", ndim=2] distances = np.empty( (<C_INT32>coords.shape[0], 
                                                                      <C_INT32>indexes.shape[0]), 
                                                                      dtype=NUMPY_FLOAT32)                                                                      
    # if periodic boundary conditions, coords must be in box
    if isPBC:
        for i from INT32_ZERO <= i < <C_INT32>indexes.shape[0]:
            _boxcoords_realdistances_to_indexcoords_PBC( atomIndex = indexes[i],
                                                         boxCoords = coords,
                                                         basis     = basis,
                                                         distances = distances[:,i],
                                                         allAtoms  = allAtoms,
                                                         ncores    = ncores)
    # if infinite boundary conditions coords must be in Cartesian normal space
    else:
        for i from INT32_ZERO <= i < <C_INT32>indexes.shape[0]:
            _realcoords_realdistances_to_indexcoords_IBC( atomIndex  = indexes[i],
                                                          realCoords = coords,
                                                          distances  = distances[:,i],
                                                          allAtoms   = allAtoms,
                                                          ncores     = ncores)
    # return distances
    return distances 



    